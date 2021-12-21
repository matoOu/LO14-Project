declare -r mode=$1
declare -r args=$2
declare -r archives="archives" ##archive by default

function archive_existe() {
   if [[ -f "archives/$1" ]]; then
     return 0
   else
     return 1
   fi
}

fucntion check_archive() {
  if ! archive_existe $1; then
    echo "Archive '$1' does not exist, please enter another archive"
  exit 1
  fi
}

function list() {
  tree $archives
}

function browse() {
  bash browse.sh $1
}

  if [ $mode == "list" ]; then
    list
  elif [ $mode == "browse" ]; then
    arch=$(echo $args | cut -d ' ' -f1)
    browse $arch
  elif [ $mode == "exit" ]; then
    exit 0
fi
