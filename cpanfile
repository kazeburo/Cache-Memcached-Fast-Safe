requires 'Cache::Memcached::Fast', '0.19';
requires 'Digest::SHA';
requires 'POSIX::AtFork', '0.02';
requires 'URI::Escape::XS', '0.09';
requires 'parent';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'File::Which';
    requires 'Proc::Guard';
    requires 'Test::More';
    requires 'Test::Skip::UnlessExistsExecutable';
    requires 'Test::TCP';
};
