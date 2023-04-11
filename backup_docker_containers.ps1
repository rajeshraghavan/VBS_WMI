 param(
	[string] $BACKUP_DIR
)

. "$PSScriptRoot\init.ps1"

$UTIL_IMAGE="${env:IBM_JAVA8_IMAGE}"

$STARTTIME=Get-Date

$DATE=Get-Date -format yyyy_MM_dd_HH_mm_ss

$LOG_FILE="${env:LOG_DIR}\backup\backup_${DATE}.log"

if (! (Test-Path "${env:LOG_DIR}\backup" -PathType Container)) {
	mkdir "${env:LOG_DIR}\backup" > $null
}

function step {
	param([string] $STEP)
	Write-Output "$STEP"
	Write-Output "$STEP" >> "$LOG_FILE"
}

# Did the user supply the BACKUP_DIR parameter?
if ([bool]($MyInvocation.BoundParameters.Keys -match "BACKUP_DIR") -eq $false) {
	# build a default one if not supplied
	$BACKUP_DIR="backup\backup_${DATE}"
}

if (Test-Path -Path "$BACKUP_DIR" -PathType Container) {
	step "Directory '${BACKUP_DIR}' already exists, we will not overwrite its contents"
	exit
}

step "Creating backup directory ${BACKUP_DIR}"
mkdir "${BACKUP_DIR}" > $null

# We need an absolute path for mounting into the Docker container
$BACKUP_DIR=$(Get-Item "$BACKUP_DIR").FullName

function backup {
	param(
		[Parameter(Mandatory=$true)]
		[string] $VOLUME_NAME,
		[Parameter(Mandatory=$true)]
		[string] $ARCHIVE_NAME
	)
  
	step "Backing up ${VOLUME_NAME} to ${ARCHIVE_NAME}"
	$cmd="docker run --rm -v `"${VOLUME_NAME}:C:\data`" -v `"${BACKUP_DIR}:C:\backup`" $UTIL_IMAGE powershell -Command `"Compress-Archive /data/* /backup/${ARCHIVE_NAME}`""
	exec { iex $cmd } # >> "${LOG_FILE}"
}

$mongo_id = $(docker ps -q --filter "name=^/mongo$")
if ( $mongo_id ) {
	step "Hot backup of MongoDB for PAW distributed restore"
	docker exec $mongo_id powershell -Command "rm /backup -r -ea Ignore; md /backup | Out-Null; mongodump /host:localhost /out:/backup *> /backup/backup.log; Compress-Archive -Force /backup/* /mongo.zip"
	# copy from a running containers fails!
}

$couchdb_id = $(docker ps -q --filter "name=^/couchdb$")
if ( $couchdb_id ) {
	step "Hot backup of CouchDB for PAW distributed restore"
	docker exec $couchdb_id powershell -Command "couchbackup --db socialdb --output /CouchDB/data/socialdb.txt"
	# We'll zip it up along with other couchdb files in the volume
}

step "Stopping Planning Analytics Workspace services"
& "${env:PAW_DIR}\scripts\paw.ps1" stop pa-gateway # Prevent connection to PAW during backup
& "${env:PAW_DIR}\scripts\paw.ps1" stop redis
& "${env:PAW_DIR}\scripts\paw.ps1" stop couchdb
& "${env:PAW_DIR}\scripts\paw.ps1" stop bss
& "${env:PAW_DIR}\scripts\paw.ps1" stop mongo

docker cp mongo:/mongo.zip "${BACKUP_DIR}/"

backup paw_couchdb couchdb.zip
backup paw_mongo_db mongo_db.zip
backup paw_redis redis.zip
backup paw_bss bss.zip

# Prepare Derby database files for PAW Distributed restore to MySQL
step "Exporting BSS tables for PAW distributed restore"
# Creates mysql.zip in the BACKUP_DIR containing all the tables
docker run --rm -t -v"${BACKUP_DIR}:C:\data" "${env:BSS_IMAGE}" powershell -Command /export.ps1 >> ${LOG_FILE}

step "Backup to ${BACKUP_DIR} complete"

step "Starting Planning Analytics Workspace services"
& "${env:PAW_DIR}\scripts\paw.ps1"

$ENDTIME=Get-Date
$ELAPSED=$($ENDTIME - $STARTTIME).TotalSeconds
step "Backup complete in $ELAPSED seconds"
 
