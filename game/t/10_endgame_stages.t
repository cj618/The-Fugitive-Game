use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Engine;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 7);
$state->{player}{meters}{law_pressure} = 90;
$state->{patterns}{repetition_score} = 80;
$state->{phones}{routing_heat} = 80;
$state->{media}{feedback_loop} = 60;
$state->{endgame}{stage} = 3;
$state->{endgame}{stage_progress} = 99;

my $capture = FugitiveGame::Engine::_advance_endgame($state);

ok($state->{endgame}{stage} >= 4, 'endgame advances to capture stage');
ok($capture, 'capture triggers at stage 4');

done_testing;
