use Durin::Data::MemoryTable;
use Durin::Metadata::Table;
use Durin::Metadata::FileExtInfo;


my $extInfo = Durin::Metadata::FileExtInfo->new_and_init("my_db.str","r");
my $ft = Durin::Data::FileTable->read($extInfo);
#my $metadata = Durin::Components::Metadata::Table
#my $metadata = Durin::Metadata::Table->new();
#$metadata->setExtInfo($extInfo);
#$metadata->read();
#my $ft = Durin::Data::FileTable->new();
#$ft->setMetadata($metadata);
$ft->open();


