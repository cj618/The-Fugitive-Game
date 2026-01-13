use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Phones;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 3);
my $action = {
    reuse_penalty => 2,
    routing_heat_delta => 5,
    timing_sensitivity => 'med'
};

my $initial = FugitiveGame::Phones::risk_modifier($state, $action);
FugitiveGame::Phones::update_after_call($state, 'payphone_row', 'morning');
FugitiveGame::Phones::update_after_call($state, 'payphone_row', 'morning');
my $after = FugitiveGame::Phones::risk_modifier($state, $action);

ok($after > $initial, 'reuse streak increases risk');

done_testing;
