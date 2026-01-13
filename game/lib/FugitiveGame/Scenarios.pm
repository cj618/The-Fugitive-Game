package FugitiveGame::Scenarios;
use strict;
use warnings;
use FugitiveGame::State;

sub available_scenarios {
    my ($state, $scenarios) = @_;
    return [] unless $state->{progress}{unlocked_chapter_mode};
    return $scenarios || [];
}

sub build_state_for_scenario {
    my ($base_state, $scenario) = @_;
    my $state = { %{$base_state} };
    FugitiveGame::State::migrate($state);
    for my $key (keys %{$scenario->{starting_state_overrides} || {}}) {
        $state->{$key} = $scenario->{starting_state_overrides}{$key};
    }
    $state->{story}{chapter_id} = $scenario->{chapter_id};
    $state->{story}{act} = $scenario->{act};
    $state->{player}{act} = $scenario->{act};
    return $state;
}

1;
