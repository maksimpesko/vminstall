#!/bin/bash
#####
##Генерируем случайный mac(macaddr)-address и hostname(hname).
##После mac будет будет соответствовать ip/mac. Если пользователь пожелает.
#####
macaddr=$(printf '00:00:00:00:%02X:%02X' $((RANDOM%256)) $((RANDOM%256)))
hname=$(printf 'vm%02X' $((RANDOM%256)))
ipaddr=$(printf '192.168.0.%02X' $((RANDOM%100)))

#####
##Переменная задает значения по умолчанию для виртуальной машины.
##Если пользователь не задаст значения при старте.
#####
default_parametrs=(
		"$hname" \
		"$macaddr"
		"$ipaddr"
##Выделяемое количество RAM
		'512' \
##Выделяемое количество ЦПУ
		'1' \
##Путь к файлу образа
		'/var/vmdisks/CentOS-7-x86_64-Minimal-1804.iso' \
##Имя сети
		'br0' \
##Путь где сохранить образ ВМ
		"/var/vmdisks/$hname" \
##Размер выделенный для диска ВМ
		'20'
		)

#####
##Задает вопрос пользователю для получения параметров и сохранения ответа в переменную vm_param.
##Так же показывает значения по умолчаю для виртуальной машины взятые из функции default_parametrs.
#####
configurations=(
		"Enter VM name. (Default: '${default_parametrs[0]}'. Example: CentOS|Web)" \
		"Enter macc-address. (Default: '${default_parametrs[1]}'. Example: 00:00:00:00:00:01)" \
		"Enter ip-address. (Default: '${default_parametrs[2]}'. Example: $ipaddr)" \
		"Enter RAM size. (Default: '${default_parametrs[3]}'. Example: 512|1024|more)" \
		"Enter count vcpus. (Default: '${default_parametrs[4]}'. Example: 1|2|more)" \
		"Enter path to ISO. (Default: '${default_parametrs[5]}'. Example: /MyDisk/ISO/CentOS-7.iso)" \
		"Enter network name. (Default: '${default_parametrs[6]}'. Example: br0)" \
		"Enter where save disk and name. (Default: '${default_parametrs[7]}'. Example: /var/data/$hname)" \
		"Enter disk size. (Default: '${default_parametrs[8]}'. Example: 10|20|40)"
		)

#####
##Переменная (массив) хранит введенные пользователем параметры виртуальной машины.
#####
vm_param=()

#####
##Функция произваодит опрос пользователя с помощью цикла.
##Цикл проходит по массиву configurations и задает вопросы для получения ответа.
##Ответ сохраняется в массив vm_param
#####
function get_param {
for i in "${!configurations[@]}"; do
    read  -p "${configurations[$i]}: " conf
    if [[ -z $conf ]]; then
	vm_param+=("${default_parametrs[$i]}")
    else
	vm_param+=($conf)
    fi
done
}

#####
##Функция создает ВМ из заданных/по умолчанию параметров.
##create $vm_param[@] передвет в функцию create_vm значения из переменной.
##Если значения не будут заданы они будут переданны из переменной default_parametrs
#####
function create_vm {
sudo virt-install \
--virt-type=kvm \
--name "${1:-${default_parametrs[0]}}" \
--ram  "${4:-${default_parametrs[3]}}" \
--vcpus="${5:-${default_parametrs[4]}}" \
--os-variant="rhl8.0" \
--hvm \
--cdrom="${6:-${default_parametrs[5]}}" \
--network="bridge:${7:-${default_parametrs[6]}}",model=virtio,mac="${2:-${default_parametrs[1]}}" \
--graphics "vnc" \
--disk path="${8:-${default_parametrs[7]}}".qcow2,size="${9:-${default_parametrs[8]}}",bus=virtio,format=qcow2
}

#####
##Функция обновляет параметры сети в реальном времени.
##Служит для связи ip/mac/hostname.
#####
function set_network {
stat_ip=${3:-${default_parametrs[3]}}
virsh net-update "${7:-${default_parametrs[6]}}" add ip-dhcp-host \
"<host mac='$macaddr' \
name='$hname' ip='$stat_ip' />" \
--live --config
}

#####
##Функция является главное (служит для вызова других функций).
##create $vm_param[@] передвет в функцию create_vm,set_network значения из переменной.
##Если значения не будут заданы они будут переданны из переменной default_parametrs
#####
function main {
get_param
set_network ${vm_param[@]}
create_vm ${vm_param[@]}
}

main