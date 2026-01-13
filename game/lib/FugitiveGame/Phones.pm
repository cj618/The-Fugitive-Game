package FugitiveGame::Phones;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp);
use FugitiveGame::State;

sub update_after_call {
    my ($state, $location_id, $slot) = @_;
    my $phones = $state->{phones};
    my $day = $state->{player}{day};

    if ($phones->{last_payphone_id} && $phones->{last_payphone_id} eq $location_id && ($day - ($phones->{last_payphone_day} || 0)) <= 2) {
        $phones->{payphone_reuse_streak}++;
    } else {
        $phones->{payphone_reuse_streak} = 1;
    }

    if ($phones->{last_call_hour_bucket} && $phones->{last_call_hour_bucket} eq $slot) {
        $phones->{routing_heat} += 5;
    } else {
        $phones->{routing_heat} += 2;
    }

    $phones->{routing_heat} += int($phones->{payphone_reuse_streak} * 3);
    $phones->{last_call_hour_bucket} = $slot;
    $phones->{last_payphone_id} = $location_id;
    $phones->{last_payphone_day} = $day;

    FugitiveGame::State::clamp_state($state);
}

sub risk_modifier {
    my ($state, $action) = @_;
    my $phones = $state->{phones};
    my $reuse_penalty = $action->{reuse_penalty} || 0;
    my $routing_heat_delta = $action->{routing_heat_delta} || 0;
    my $timing_sensitivity = $action->{timing_sensitivity} || 'low';

    my $modifier = 0;
    $modifier += $phones->{payphone_reuse_streak} * $reuse_penalty;
    $modifier += int(($phones->{routing_heat} + $routing_heat_delta) / 10);

    if ($timing_sensitivity eq 'high') {
        $modifier += 6;
    } elsif ($timing_sensitivity eq 'med') {
        $modifier += 3;
    }

    return clamp($modifier, 0, 30);
}

1;
