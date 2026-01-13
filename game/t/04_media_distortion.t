use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Media;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 2);
$state->{player}{meters}{law_pressure} = 20;
$state->{player}{meters}{reputation_media} = 60;
$state->{player}{meters}{reputation_underground} = 10;
$state->{media}{momentum} = 40;
$state->{media}{accuracy} = 15;
$state->{media}{simplification} = 0;
$state->{media}{feedback_loop} = 0;

my $before_pressure = $state->{player}{meters}{law_pressure};
FugitiveGame::Media::update_media($state);

ok($state->{media}{simplification} > 0, 'simplification increases with momentum');
ok($state->{media}{feedback_loop} >= 0, 'feedback loop is tracked');
ok($state->{player}{meters}{law_pressure} >= $before_pressure, 'feedback loop boosts law pressure');

done_testing;
