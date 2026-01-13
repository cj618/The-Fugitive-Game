package FugitiveGame::Relationships;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp);
use FugitiveGame::State;

sub daily_update {
    my ($state) = @_;
    my $day = $state->{player}{day};
    for my $npc_id (keys %{$state->{relationships} || {}}) {
        my $rel = $state->{relationships}{$npc_id};
        if (($rel->{last_contact_day} || 0) < $day) {
            $rel->{drift} += 3;
            $rel->{closeness} -= 2;
        }
        $rel->{drift} = clamp($rel->{drift}, 0, 100);
        $rel->{closeness} = clamp($rel->{closeness}, 0, 100);
    }

    FugitiveGame::State::clamp_state($state);
}

sub record_contact {
    my ($state, $npc_id, $outcome) = @_;
    my $rel = $state->{relationships}{$npc_id};
    return unless $rel;
    $rel->{last_contact_day} = $state->{player}{day};
    $rel->{last_outcome} = $outcome || 'neutral';
    $rel->{drift} -= 5;
    $rel->{closeness} += 4;
    $rel->{drift} = clamp($rel->{drift}, 0, 100);
    $rel->{closeness} = clamp($rel->{closeness}, 0, 100);
}

sub is_available {
    my ($state, $npc_id) = @_;
    my $rel = $state->{relationships}{$npc_id};
    return 1 unless $rel;
    return $rel->{drift} < 70;
}

1;
