package Durin::FlexibleIO::System;

use Durin::FlexibleIO::IORegistry;
use Durin::FlexibleIO::DataTypeMappingRegistry;

sub BEGIN
{
  my @IO_MODULES = ("Durin::Data::IO::TSIOStandard","Durin::Data::IO::FTIOStandard","Durin::Classification::IO::CTSIOStandard","Durin::TAN::IO::TANIOStandard","Durin::TAN::IO::TANIONetica","Durin::Data::IO::FTIOMineset","Durin::Classification::IO::CTSIOMineset","Durin::Data::IO::FTIOXML","Durin::Components::IO::DataXML");
  my ($module);
  print "Loading FlexibleIO system\n";
  foreach $module (@IO_MODULES)
    {
      print "\tLoading $module\n";
      eval "require $module";
      if ($@) {
	print "Troubles loading $module:\n$@\n";
      }
      import $module;
      $IOHandler = new $module ();
      Durin::FlexibleIO::IORegistry->register(${$module."::IO_CLASS"},${$module."::IO_FORMAT"},$IOHandler);
}
print "FlexibleIO system loaded\n";
}

#use Durin::Data::TSIOStandard;
#use Durin::Data::CTSIOCerquides;

# Durin::FlexibleIO::IORegistry->register("Durin::Data::TableSchema","Standard",Durin::Data::TSIOStandard->new()); 

# Durin::FlexibleIO::IORegistry->register("Durin::Classification::ClassedTableSchema","Cerquides",Durin::Data::CTSIOCerquides->new());

1;
