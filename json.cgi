#!/usr/bin/perl -w

use strict;
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/addons/SimpleJSON.plugin/lib" : 'addons/SimpleJSON.plugin/lib';
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : 'lib';
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/extlib" : 'extlib';
use MT::Bootstrap App => 'Melody::API::SimpleJSON';
