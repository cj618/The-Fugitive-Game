use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Events;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 1);
$state->{player}{day} = 2;

my $events = [
    {
        id => 'test_event',
        name => 'Test Event',
        trigger => { day => 2 },
        effects => { meters => { stress => 5 } },
        narration => 'Triggered.'
    }
];

my $triggered = FugitiveGame::Events::check_events($state, $events);

is(scalar @$triggered, 1, 'event triggered');
is($state->{player}{meters}{stress}, 25, 'event effects applied');

my $again = FugitiveGame::Events::check_events($state, $events);

is(scalar @$again, 0, 'event only triggers once');

done_testing;
