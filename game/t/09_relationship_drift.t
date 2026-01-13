use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Relationships;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 6);
$state->{relationships}{"ally"} = {
    trust => 10,
    risk => 10,
    closeness => 10,
    drift => 69,
    last_contact_day => 0,
    last_outcome => 'neutral'
};

FugitiveGame::Relationships::daily_update($state);

ok($state->{relationships}{ally}{drift} > 69, 'drift increases');
ok(!FugitiveGame::Relationships::is_available($state, 'ally'), 'relationship becomes unavailable');

done_testing;
