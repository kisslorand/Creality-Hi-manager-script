#!/bin/sh

# Define the directory where the stock G-code files are stored
STOCK_GCODE_DIR=/rom/usr/share/klipper/gcodes/F018

# Define the directory where the user's G-code files are stored
USER_GCODE_DIR=/mnt/UDISK/printer_data/gcodes

# Define the file where the klipper script is stored
KLIPPER_FILE="/etc/init.d/klipper"

# Initialize variables
STOCK_GCODES_PRESENT=false

# Function to show progress
show_progress() {
  count=$1
  total=$2
  bar_len=$((count * 50 / total))
  bar=$(printf "%-${bar_len}s" "#" | tr ' ' '#')
  pad=$((50 - bar_len))
  pad_str=$(printf "%${pad}s")
  percent=$((count * 100 / total))
  printf "\r[%s%s] %3d%% (%d/%d)" "$bar" "$pad_str" "$percent" "$count" "$total"
}

# Function to restore G-code files
restore_gcode() {
  total=$(ls -1 "${STOCK_GCODE_DIR}" | wc -l)
  count=0

  echo "Restoring G-code files..."
  echo

  for file in "${STOCK_GCODE_DIR}"/*; do
    filename=$(basename "$file")
    cp "${STOCK_GCODE_DIR}/${filename}" "${USER_GCODE_DIR}/"

    count=$((count + 1))
    show_progress $count $total
  done

  echo
  echo
  echo "Restore complete!"
}

# Function to delete G-code files
delete_gcode() {
  total=$(ls -1 "${STOCK_GCODE_DIR}" | wc -l)
  count=0

  echo "Deleting G-code files..."
  echo

  for file in "${STOCK_GCODE_DIR}"/*; do
    filename=$(basename "$file")
    rm -f "${USER_GCODE_DIR}/${filename}"

    count=$((count + 1))
    show_progress $count $total
  done

  echo
  echo
  echo "Delete complete!"
}

# Function to comment out klipper script
comment_out_klipper_script() {
  sed -i '/GCODE_PATH=\$ROM_GCODE_DIR\/${gcode_dir}/,/^    sync$/ { s/^/#/ }' "$KLIPPER_FILE"
}

# Function to uncomment klipper script
uncomment_klipper_script() {
  sed -i '/#    GCODE_PATH=\$ROM_GCODE_DIR\/${gcode_dir}/,/^#    sync$/ { s/^#// }' "$KLIPPER_FILE"
}

# Check if stock G-code files are present in user directory
for file in "${STOCK_GCODE_DIR}"/*; do
  filename=$(basename "$file")
  if [ -f "${USER_GCODE_DIR}/${filename}" ]; then
    STOCK_GCODES_PRESENT=true
    break
  fi
done

# Check if klipper script is commented out
if grep -q '^#\s*GCODE_PATH=\$ROM_GCODE_DIR/\${gcode_dir}' "$KLIPPER_FILE"; then
  GCODE_SYNC_ENABLED=false
else
  GCODE_SYNC_ENABLED=true
fi

# Display current state
echo "Current state:"
echo "Stock Creality gcode files enabled: ${GCODE_SYNC_ENABLED}"
echo "Stock G-code files present: ${STOCK_GCODES_PRESENT}"

# Disable/enable the Stock Creality gcode files
if [ "$GCODE_SYNC_ENABLED" == true ]; then
  read -p "Do you want to disable the stock Creality gcode files? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    comment_out_klipper_script
    delete_gcode
    echo "Stock Creality gcode files have been disabled."
  elif [ "$STOCK_GCODES_PRESENT" == false ]; then
    echo "Stock G-code files are not present in the user G-code directory."
    echo "They will be synced on the next boot."
    read -p "Do you want to sync the Stock Creality gcode files now? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      restore_gcode
    fi
  fi
else
  read -p "Do you want to enable the stock Creality gcode files? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    uncomment_klipper_script
    restore_gcode
    echo "Stock Creality gcode files have been enabled."
  elif [ "$STOCK_GCODES_PRESENT" == true ]; then
    echo "Stock G-code files are present in the user G-code directory."
    read -p "Do you want to delete them? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      delete_gcode
    fi
  fi
fi
