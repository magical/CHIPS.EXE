set -eu
i=2
for file in seg2.asm logic.asm seg4.asm seg5.asm seg6.asm movement.asm sound.asm digits.asm; do
    echo "; $file"
    sed -E 's/^(\w+):$/func \1/' <$file |
    awk -e '/^; [0-9a-f]+$/ { addr=$2; } /^func / { printf("EXTERN %-30s; %d:%s\n", $2, '$i', addr); }'
    echo
    i=$((i+1))
done
#for file in info/*.sym; do
#    echo "; $file"
#    module=$(basename "$file" .sym)
#    awk -e '/^[0-9]+ \w+/ { if ($2 == "equate" || $2 == "varargs") { sym=$3 } else { sym=$2 }; printf("EXTERN %-30s; @%d\n", "'"$module"'." sym, $1) }' <$file
#    echo
#done
