package FugitiveGame::Events;
use strict;
use warnings;
use FugitiveGame::Actions;
use FugitiveGame::Agency;

sub check_events {
    my ($state, $events) = @_;
    my @triggered;
    for my $event (@{$events || []}) {
        my $id = $event->{id};
        next if $state->{player}{flags}{"event_$id"};
        next unless _trigger_met($state, $event->{trigger});
        FugitiveGame::Actions::apply_effects($state, $event->{effects} || {});
        if ($event->{agency_effects}) {
            FugitiveGame::Agency::apply_effects($state, $event->{agency_effects});
        }
        $state->{player}{flags}{"event_$id"} = 1;
        push @triggered, $event;
    }
    return \@triggered;
}

sub _trigger_met {
    my ($state, $trigger) = @_;
    return 0 unless $trigger;
    if (my $day = $trigger->{day}) {
        return 0 unless $state->{player}{day} >= $day;
    }
    if (my $meter = $trigger->{meter}) {
        my ($key, $value) = %{$meter};
        return 0 unless $state->{player}{meters}{$key} >= $value;
    }
    if (my $flag = $trigger->{flag}) {
        return 0 unless $state->{player}{flags}{$flag};
    }
    return 1;
}

1;
