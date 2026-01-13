use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Epilogue;
use FugitiveGame::Scenarios;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 8);
my $scenarios = [
    { scenario_id => 'test', title => 'Test Scenario' }
];

is(scalar @{FugitiveGame::Scenarios::available_scenarios($state, $scenarios)}, 0, 'chapter mode locked');

FugitiveGame::Epilogue::complete_campaign($state);

is(scalar @{FugitiveGame::Scenarios::available_scenarios($state, $scenarios)}, 1, 'chapter mode unlocked');

done_testing;
