set -eu
i=1
for file in crt.asm seg2.asm logic.asm seg4.asm seg5.asm seg6.asm movement.asm sound.asm digits.asm; do
    echo "; $file"
    sed -E 's/^(\w+):$/func \1/' <$file |
    awk -e '/^; [0-9a-f]+$/ { addr=$2; } /^func / { printf("EXTERN %-30s; %d:%s\n", $2, '$i', addr); }'
    echo
    i=$((i+1))
done
