# # Retried StoredHash Network (DB) operations
# Allow over-the-network methods to be retried when network has volatile connectivity (transient outages, etc.).
# 
# Load this package into the runtime of your app that uses StoredHash.
# Just loading it will convert all StoredHash over-the-network methods (listed here) into using DPUT::Retrier.
# 
# ## Examples of using
# After loading StoredHash (by `use StoredHash;`) but before starting to use it's methods do:
# ```
# ....
# use StoredHash::Retry;
# ...
# ```
# The module will auto-initialize retrier with default settings (cnt = 10, delay = 50).
# In case you want to change these, do a re-init:
# ```
# ...
# use StoredHash::Retry;
# $StoredHash::Retry::rcnt = 20;
# $StoredHash::Retry::rdelay = 40;
# StoredHash::Retry::init();
# ...
# ```

package StoredHash::Retry;
# Load
use DPUT;
use DPUT::Retrier;
use Data::Dumper;
our $rcnt = 10;
our $rdelay = 5;
# use strict;
# use warnings;
my @marr; #  See unique init below.
my $meths;
my $debug = 0;
# my $ins;
# my $upd;
# my $load;
# Store CODE refs to originals
BEGIN {
  $meths = {};
  @marr = ('insert', 'update', 'exists', 'load', 'loadset', 'count'); # 'delete';
  # $ins = \${"StoredHash::insert"}; # SCAL ref
  $ins  = \&StoredHash::insert;
  # $load = \&StoredHash::load;
  $load = \&{"StoredHash::load"}; # ALT, OK
  ${"$load"} = \&{"StoredHash::load"}; # ????
  # print("Got original insert: '$ins'\n");
  # print("Got original load: '$load'\n");
  map({ $meths->{$_} = \&{"StoredHash::$_"}; } @marr); # Gets syms ok, but usage later does not work
  # map({ ${"$_"} = \&{"StoredHash::$_"}; } @marr); # Into scalars. Ok, BUT EVEN Hash works, do not use N scalars.
  # print("METHS: ".Dumper($meths)); # Problem: sub { "DUMMY" }
  # OUTPUT: map({ print("ORIG: $_: ". $meths->{$_}."\n"); } @marr);
};

our $retrier;
# Init with module global vals. Call again to change.
init();
# Init retrier. Can be called multiple times after changing package globals for 
sub init {
  # 'raw' - return raw/original values from callback instead of only 1/0
  $retrier = new DPUT::Retrier('cnt' => $rcnt, 'delay' => $rdelay, 'raw' => 1);
}
#### New wrapped methods ##########
sub _insert {
  my @p = @_;
  $debug && print("Retry insert running ...\n");
  return $retrier->run(sub { return $meths->{insert}->(@p);  });
}

sub _update {
  my @p = @_;
  $debug && print("Retry update running ...\n");
  return $retrier->run(sub { return $meths->{update}->(@p);  });
}
sub _exists {
  my @p = @_;
  $debug && print("Retry exists running ...\n");
  return $retrier->run(sub { return $meths->{'exists'}->(@p);  });
    
}
sub _load {
  my @p = @_;
  $debug && print("Retry load running\n"); #  $load / $meths->{load} ...
  # return $retrier->run(sub { return $load->(@p);  });
  return $retrier->run(sub { return $meths->{load}->(@p);  });
}
sub _loadset {
  my @p = @_;
  $debug && print("Retry loadset running $load / $meths->{load} ...\n");
  return $retrier->run(sub { return $meths->{loadset}->(@p);  });
}

sub _count {
  my @p = @_;
  # my @info0 = caller(0);
  # my @info1 = caller(1);
  # print("I-0:".Dumper(\@info0)."\n");
  # print("I-1:".Dumper(\@info1)."\n");
  $debug && print("Retry count running ...\n");
  return $retrier->run(sub { return $meths->{count}->(@p);  });
}

sub _delete {
  my @p = @_;
  $debug && print("Retry delete running\n");
  return $retrier->run(sub { return $meths->{'delete'}->(@p);  });
}



#print("Got new: _insert ".\&_insert."\n");
#print("Got new: _load   ".\&_load."\n");
# map({ print("StoredHash::Retrier::_$_ = ".\&{"StoredHash::Retrier::_$_"}."\n") } @marr); # Wrong !?
# NOTE: The non-existing methods STILL DO get a CODEREF value here.
OUTPUT2: map({ print("StoredHash::Retrier::_$_ = ".\&{"_$_"}."\n") } @marr); # Short/ Correct ?
# my $rmeths = {};
# map({ $rmeths->{$_} = \&{"_$_"}; } @marr); # Short/ Correct ?
# *{StoredHash::insert} = \&_insert;
# *{StoredHash::load} = \&_load;
map({ *{"StoredHash::$_"} = \&{"_$_"}; } @marr); # OK: Short/ Correct ?
# NOT: Collect Current 

# 
# print("At end: _insert ".\&_insert."\n");
# print("At end: StoredHash::insert ".\&StoredHash::insert."\n");
# print("At end: StoredHash::load   ".\&StoredHash::load."\n");
map({ print("FINAL: StoredHash::$_ = ".\&{"StoredHash::$_"}."\n") } @marr);

1;
