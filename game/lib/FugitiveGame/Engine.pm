package FugitiveGame::Engine;
use strict;
use warnings;
use FugitiveGame::UI;
use FugitiveGame::Actions;
use FugitiveGame::Adversary;
use FugitiveGame::Events;
use FugitiveGame::State;
use FugitiveGame::Save;
use FugitiveGame::Chapters;
use FugitiveGame::Media;
use FugitiveGame::Narration;
use FugitiveGame::Surveillance;
use FugitiveGame::Relationships;
use FugitiveGame::Epilogue;
use FugitiveGame::Util qw(log_line);

my @slots = qw(morning afternoon night);

sub run {
    my ($state, $content, $save_dir) = @_;
    FugitiveGame::State::ensure_npcs($state, $content->{npcs});
    FugitiveGame::State::migrate($state);
    if ($content->{agencies}) {
        for my $agency (@{$content->{agencies}}) {
            my $id = $agency->{id};
            $state->{agencies}{$id} ||= {};
            for my $key (qw(pressure coordination delay)) {
                $state->{agencies}{$id}{$key} = $agency->{$key} if defined $agency->{$key};
            }
        }
    }

    log_line($state, "RNG seed: $state->{player}{rng}{seed}");

    while (1) {
        _update_act($state);
        FugitiveGame::Chapters::update_chapter($state, $content->{chapters});

        if ($state->{player}{flags}{identity_burned} && $state->{player}{slot} eq 'morning') {
            FugitiveGame::Actions::forced_identity_choice($state);
        }

        my $location = _location($state, $content);
        my $chapter_title = FugitiveGame::Chapters::get_chapter_title($content->{chapters}, $state->{story}{chapter_id});
        FugitiveGame::UI::hud($state, $location, $chapter_title);
        my $headlines = FugitiveGame::Media::pick_headlines($state, $content->{headlines});
        FugitiveGame::UI::press_wire($headlines);
        my $valid = FugitiveGame::Actions::valid_actions($state, $content->{actions}, $content);
        my @options = map { $_->{name} } @$valid;
        push @options, 'Status', 'Save', 'Quit';
        my $choice = FugitiveGame::UI::menu_choice('Choose an action:', \@options, 1);

        my $status_index = @$valid;
        my $save_index = @$valid + 1;
        my $quit_index = @$valid + 2;

        if ($choice =~ /^status$/i || ($choice =~ /^\d+$/ && $choice == $status_index)) {
            FugitiveGame::UI::status($state);
            next;
        }
        if ($choice =~ /^save$/i || ($choice =~ /^\d+$/ && $choice == $save_index)) {
            my $path = FugitiveGame::Save::save_state($state, $save_dir);
            print "Saved to $path\n";
            next;
        }
        if ($choice =~ /^quit$/i || ($choice =~ /^\d+$/ && $choice == $quit_index)) {
            my $confirm = FugitiveGame::UI::confirm('Quit to menu?');
            return 'quit' if $confirm;
            next;
        }

        my $action = $valid->[$choice];
        if ($action->{category} && $action->{category} eq 'move') {
            my $destination = _choose_location($content);
            $action = { %{$action}, move_to => $destination };
        }

        my $result = FugitiveGame::Actions::resolve_action($state, $action, $content, $location);
        my $tone = FugitiveGame::Narration::current_tone($state);
        my $rendered = FugitiveGame::Narration::render_text($result->{text}, $tone, { tone_tags => $action->{tone_tags} || [] });
        print "\n$rendered\n";
        if ($result->{outcome} eq 'exposure') {
            $state->{player}{flags}{exposure_event} = 1;
        } else {
            $state->{player}{flags}{exposure_event} = 0;
        }
        if ($action->{id} eq 'lie_low') {
            $state->{player}{flags}{lie_low} = 1;
        } else {
            $state->{player}{flags}{lie_low} = 0;
        }

        my $events = FugitiveGame::Events::check_events($state, $content->{events_by_act}{$state->{story}{act}});
        for my $event (@$events) {
            my $event_chapter_title = FugitiveGame::Chapters::get_chapter_title($content->{chapters}, $event->{chapter_ref});
            print "\nChapter: $event_chapter_title\n" if $event_chapter_title;
            my $event_text = FugitiveGame::Narration::render_text($event->{narration}, $tone, { tone_tags => $event->{tone_tags} || [] });
            print "Event: $event->{name}\n$event_text\n";
            log_line($state, "Event: $event->{id} chapter=$event->{chapter_ref} act=$state->{story}{act}");
        }

        if ($action->{check_signal}) {
            my $signal = FugitiveGame::Surveillance::generate_signal($state, { action => $action->{id} });
            log_line($state, "Signal: $signal->{signal_type} truth=$signal->{truth}");
        }

        FugitiveGame::Media::update_media($state);
        FugitiveGame::Adversary::escalate($state);

        _advance_time($state);

        if (_advance_endgame($state)) {
            my $packet = FugitiveGame::Epilogue::build_packet($state);
            FugitiveGame::Epilogue::complete_campaign($state);
            FugitiveGame::Save::save_progress($state->{progress}, $save_dir);
            print "\n" . join("\n", @$packet) . "\n";
            return 'end';
        }
    }
}

sub _advance_time {
    my ($state) = @_;
    my $slot = $state->{player}{slot};
    if ($slot eq 'morning') {
        $state->{player}{slot} = 'afternoon';
    } elsif ($slot eq 'afternoon') {
        $state->{player}{slot} = 'night';
    } else {
        _end_of_day($state);
        $state->{player}{day}++;
        $state->{player}{slot} = 'morning';
    }
}

sub _end_of_day {
    my ($state) = @_;
    my $decay = 1 + ($state->{daily}{exposure} || 0);
    $decay += ($state->{daily}{high_risk} || 0);
    $decay += ($state->{daily}{travel} || 0);
    $decay += ($state->{daily}{payphone} || 0);
    $decay = 5 if $decay > 5;
    for my $identity (@{$state->{player}{identities}}) {
        $identity->{exposure} += $decay;
        if ($identity->{exposure} >= 100) {
            $state->{player}{flags}{identity_burned} = 1;
        }
    }
    $state->{player}{meters}{sleep_debt} += 2;
    $state->{player}{meters}{equipment_integrity} -= ($state->{daily}{travel} || 0);
    $state->{player}{meters}{safehouse_stability} -= 1;
    $state->{daily} = { exposure => 0, high_risk => 0, travel => 0, payphone => 0 };
    $state->{story}{chapter_day_index}++;
    FugitiveGame::Relationships::daily_update($state);
    if (($state->{story}{act} || 1) >= 2 && ($state->{player}{meters}{compliance} || 0) < 30) {
        $state->{player}{meters}{law_pressure} += 4;
        $state->{player}{flags}{probation_clampdown} = 1;
    }
    FugitiveGame::State::clamp_state($state);
}

sub _location {
    my ($state, $content) = @_;
    for my $location (@{$content->{locations}}) {
        return $location if $location->{id} eq $state->{player}{location_id};
    }
    return $content->{locations}[0];
}

sub _choose_location {
    my ($content) = @_;
    my @names = map { $_->{name} } @{$content->{locations}};
    my $choice = FugitiveGame::UI::menu_choice('Choose a destination:', \@names);
    return $content->{locations}[$choice]{id};
}

sub _alpha_cutoff {
    my ($state) = @_;
    print "\n=== Alpha Cutoff ===\n";
    print "Alpha cutoff: investigation converges.\n";
    FugitiveGame::UI::status($state);
    print "============\n";
    log_line($state, 'Alpha cutoff reached.');
}

sub _advance_endgame {
    my ($state) = @_;
    my $endgame = $state->{endgame};
    my $meters = $state->{player}{meters};
    my $media = $state->{media};
    my $patterns = $state->{patterns};
    my $phones = $state->{phones};

    my $increment = int(($meters->{law_pressure} + $patterns->{repetition_score} + $phones->{routing_heat} + $media->{feedback_loop}) / 80);
    $increment = 1 if $increment < 1;
    $endgame->{stage_progress} += $increment;
    log_line($state, "Endgame: stage=$endgame->{stage} progress=$endgame->{stage_progress}");

    if ($endgame->{stage_progress} >= 100) {
        $endgame->{stage}++;
        $endgame->{stage_progress} = 0;
    }
    FugitiveGame::State::clamp_state($state);
    return $endgame->{stage} >= 4;
}

sub _update_act {
    my ($state) = @_;
    my $day = $state->{player}{day};
    my $pressure = $state->{player}{meters}{law_pressure} || 0;
    my $act = $state->{story}{act} || 1;

    if ($act == 1 && ($day >= 3 || $pressure >= 30 || $state->{player}{flags}{probation_clampdown})) {
        $act = 2;
    } elsif ($act == 2 && ($day >= 6 || $pressure >= 50)) {
        $act = 3;
    } elsif ($act == 3 && ($day >= 9 || $pressure >= 70)) {
        $act = 4;
    } elsif ($act == 4 && ($day >= 11 || $pressure >= 85)) {
        $act = 5;
    }

    $state->{story}{act} = $act;
    $state->{player}{act} = $act;
}

1;
