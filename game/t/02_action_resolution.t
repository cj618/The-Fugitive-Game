use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Actions;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 1);
$state->{player}{meters}{stress} = 0;

my $action = {
    id => 'test_action',
    base_risk => 50,
    valid_slots => ['morning'],
    skill_weights => {},
    outcomes => {
        success => { text => 'success', effects => {} },
        partial => { text => 'partial', effects => {} },
        exposure => { text => 'exposure', effects => {} },
    },
};

my $location = { id => 'apartment', risk_modifier => 0 };
my $result = FugitiveGame::Actions::resolve_action($state, $action, {}, $location);

is($result->{roll}, 91, 'deterministic roll');
is($result->{outcome}, 'success', 'deterministic outcome');

done_testing;
