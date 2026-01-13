package FugitiveGame::Patterns;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp);
use FugitiveGame::State;

sub update_after_action {
    my ($state, $action_id, $location_id, $slot) = @_;
    my $patterns = $state->{patterns};
    my $day = $state->{player}{day};

    push @{$patterns->{recent_actions}}, {
        day => $day,
        slot => $slot,
        action_id => $action_id,
        location_id => $location_id,
    };

    if (@{$patterns->{recent_actions}} > 12) {
        shift @{$patterns->{recent_actions}};
    }

    my %slot_counts;
    my %action_counts;
    my %location_counts;
    my $payphone_actions = 0;
    for my $entry (@{$patterns->{recent_actions}}) {
        $slot_counts{$entry->{slot}}++;
        $action_counts{$entry->{action_id}}++;
        $location_counts{$entry->{location_id}}++;
        $payphone_actions++ if $entry->{action_id} =~ /phone/;
    }

    my $repetition = 0;
    $repetition += _max_count(\%slot_counts) * 5;
    $repetition += _max_count(\%action_counts) * 6;
    $repetition += _max_count(\%location_counts) * 6;
    $repetition += $payphone_actions * 3;

    $patterns->{repetition_score} = clamp($repetition, 0, 100);
    $patterns->{habit_flags} = {
        night_owl => ($slot_counts{night} || 0) >= 4 ? 1 : 0,
        payphone_dependent => $payphone_actions >= 4 ? 1 : 0,
        stationary => ($location_counts{$location_id} || 0) >= 4 ? 1 : 0,
    };

    FugitiveGame::State::clamp_state($state);
}

sub risk_modifier {
    my ($state, $action_id, $location_id, $slot) = @_;
    my $patterns = $state->{patterns};
    my $modifier = int(($patterns->{repetition_score} || 0) / 12);

    if ($patterns->{habit_flags}{payphone_dependent} && $action_id =~ /phone/) {
        $modifier += 6;
    }
    if ($patterns->{habit_flags}{night_owl} && $slot eq 'night') {
        $modifier += 4;
    }
    if ($patterns->{habit_flags}{stationary} && $location_id) {
        $modifier += 4;
    }

    return clamp($modifier, 0, 25);
}

sub _max_count {
    my ($counts) = @_;
    my $max = 0;
    for my $value (values %{$counts || {}}) {
        $max = $value if $value > $max;
    }
    return $max;
}

1;
