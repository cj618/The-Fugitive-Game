package FugitiveGame::Engine;
use strict;
use warnings;
use FugitiveGame::UI;
use FugitiveGame::Actions;
use FugitiveGame::Adversary;
use FugitiveGame::Events;
use FugitiveGame::State;
use FugitiveGame::Save;
use FugitiveGame::Util qw(log_line);

my @slots = qw(morning afternoon night);

sub run {
    my ($state, $content, $save_dir) = @_;
    FugitiveGame::State::ensure_npcs($state, $content->{npcs});

    log_line($state, "RNG seed: $state->{player}{rng}{seed}");

    while (1) {
        if ($state->{player}{flags}{identity_burned} && $state->{player}{slot} eq 'morning') {
            FugitiveGame::Actions::forced_identity_choice($state);
        }

        my $location = _location($state, $content);
        FugitiveGame::UI::hud($state, $location);
        my $valid = FugitiveGame::Actions::valid_actions($state, $content->{actions});
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
        print "\n$result->{text}\n";
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

        my $events = FugitiveGame::Events::check_events($state, $content->{events});
        for my $event (@$events) {
            print "\nEvent: $event->{name}\n$event->{narration}\n";
            log_line($state, "Event: $event->{id}");
        }

        FugitiveGame::Adversary::escalate($state);

        _advance_time($state);

        if ($state->{player}{meters}{law_pressure} >= 100) {
            _alpha_cutoff($state);
            return 'end';
        }
        if ($state->{player}{day} > 7) {
            _alpha_cutoff($state);
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
    $state->{daily} = { exposure => 0, high_risk => 0, travel => 0, payphone => 0 };
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

1;
