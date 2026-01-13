use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Patterns;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 4);

for (1..6) {
    FugitiveGame::Patterns::update_after_action($state, 'use_payphone', 'payphone_row', 'night');
}

ok($state->{patterns}{repetition_score} > 0, 'repetition score increases');
ok($state->{patterns}{habit_flags}{payphone_dependent}, 'payphone dependence flagged');

done_testing;
