#!/bin/bash
set -euo pipefail

# Direct rclone mount wrapper using environment variables
# Usage: mount-remote.sh <remote_type> <remote_path> <mount_point> [rclone_options...]

# Check arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <remote_type> <remote_path> <mount_point> [remote_name] [rclone_options...]"
    echo "   or: $0 <remote_name> <remote_type> <remote_path> <mount_point> [rclone_options...]"
    echo ""
    echo "Examples:"
    echo "  $0 b2 :my-bucket /mnt/b2                    # Uses auto-generated name 'b2_remote'"
    echo "  $0 ftp :/ /mnt/ftp                          # Uses auto-generated name 'ftp_remote'"
    echo "  $0 myb2 b2 :my-bucket /mnt/b2               # Uses custom name 'myb2'"
    echo "  $0 server1 ftp :/ /mnt/ftp1                 # Uses custom name 'server1'"
    echo ""
    echo "Set credentials via environment variables:"
    echo "  RCLONE_CONFIG_<REMOTE_NAME>_TYPE=<type>"
    echo "  RCLONE_CONFIG_<REMOTE_NAME>_HOST=<host>"
    echo "  etc..."
    exit 1
fi

# Parse arguments - detect if remote name is provided
if [[ "$2" =~ ^: ]] || [[ "$2" == /* ]]; then
    # Format: <type> <path> <mount> [options...]
    REMOTE_TYPE="$1"
    REMOTE_NAME="${REMOTE_TYPE}_remote"
    REMOTE_PATH="$2"
    MOUNT_POINT="$3"
    shift 3
else
    # Format: <name> <type> <path> <mount> [options...]
    REMOTE_NAME="$1"
    REMOTE_TYPE="$2"
    REMOTE_PATH="$3"
    MOUNT_POINT="$4"
    shift 4
fi
EXTRA_OPTIONS="$@"

# Create mount directory if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Build the rclone command - use remote name directly
RCLONE_CMD="rclone mount ${REMOTE_NAME}${REMOTE_PATH} ${MOUNT_POINT}"

# Add backend-specific optimizations
case "$REMOTE_TYPE" in
    b2)
        # B2 optimized settings - handles many transfers well
        RCLONE_CMD="$RCLONE_CMD --read-only --transfers 20 --dir-cache-time 720h --vfs-cache-mode full --checkers 8"
        ;;
    ftp)
        # FTP optimized settings - more conservative
        RCLONE_CMD="$RCLONE_CMD --read-only --transfers 4 --dir-cache-time 24h --vfs-cache-mode full --tpslimit 10"
        ;;
    sftp)
        # SFTP settings - similar to FTP but can handle more
        RCLONE_CMD="$RCLONE_CMD --read-only --transfers 8 --dir-cache-time 48h --vfs-cache-mode full --tpslimit 20"
        ;;
    *)
        # Generic defaults for other backends
        RCLONE_CMD="$RCLONE_CMD --read-only --dir-cache-time 168h --vfs-cache-mode full"
        ;;
esac

# Add common stability options
RCLONE_CMD="$RCLONE_CMD --log-level INFO"

# Add any extra options passed as arguments
if [ -n "$EXTRA_OPTIONS" ]; then
    RCLONE_CMD="$RCLONE_CMD $EXTRA_OPTIONS"
fi

echo "Mounting ${REMOTE_TYPE}${REMOTE_PATH} to $MOUNT_POINT"
echo "Command: $RCLONE_CMD"

# Execute rclone mount in foreground
exec $RCLONE_CMD
