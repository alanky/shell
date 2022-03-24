#!/bin/bash

##########################################################
# Author:                                                #
#   Alanky1992                                           #
# Usage:                                                 #  
#   bash images.sh pull                                  #
#   bash images.sh push [镜像仓库/项目]                  #
#   bash images.sh setimages [镜像仓库/项目] [名称空间]  #
# Example:                                               #
#   pull                                   拉取镜像      #
#   push reg.local:5000/wod/               推送镜像      # 
#   setimages reg.local:5000/wod/ apaas    更新镜像      #
#                                                        #
##########################################################

if [ ! -e imgs ]
then
mkdir imgs
fi

if [ ! -e logs ]
then
mkdir logs
fi

date=$(date +"%Y-%m-%d %H:%M:%S")


for image_url in $(cat imglist)

do
   # image_tag is xxx:v1.2.3
   # image_name is xxx
   image_tag=$(echo | awk '{split("'${image_url}'", array, "/");print array[3]}')
   image_name=$(echo | awk '{split("'${image_tag}'", array, ":");print array[1]}')

   case $1 in
     "pull" )
     # pull images
     if
       docker pull $image_url &>/dev/null
     then
       echo $image_url "pull img success!"
     else
       echo $date $image_url "pull error" |tee -a  ./logs/error.log
     fi
     # save images
     if
       docker save -o ./imgs/$image_tag.tar  $image_url  &>/dev/null
      then
        echo $image_tag "save img success!"
      else
        echo $date $image_tag  "save error" |tee -a  ./logs/error.log
      fi
   ;;

     "push" )
      # load images
      # 设置镜像仓库+项目  
      newaddr=$2
      if
        imgs -name "*_*"
      then 
        find imgs -name "*_*" | while read id; do mv $id ${id/_/:}; done 
      fi

      if
        docker load -i ./imgs/${image_tag}.tar  &>/dev/null
      then
        echo  ${image_tag}.tar "load img success!"
      else
        echo $date $image_tag.tar "load error" |tee -a ./logs/error.log
      fi
      # tag images
      if
        docker tag $image_url $newaddr$image_tag &>/dev/null
      then
        echo $image_url "tag img success!"
      else
        echo $date $image_url "tag error" |tee -a ./logs/error.log
      fi
      # push images
      if
        docker push $newaddr$image_tag  &>/dev/null
      then
        echo $newaddr$image_tag "push img success!"
      else
        echo $date ${newaddr}${image_tag} "push error" |tee -a ./logs/error.log
      fi
    ;;
    
     "setimages")
      # set images
      # 设置镜像仓库+项目
      newaddr=$2
      if
        kubectl  set image deploy/$image_name $image_name=${newaddr}${image_tag} -n $3
        echo $newaddr
      then
        echo $image_name "set success!"
      else
        echo $date $image_name "set image error" |tee -a ./logs/error.log
      fi
     ;;
  
     *)
      echo "
##########################################################
# Usage:                                                 #
#   bash images.sh pull                                  #
#   bash images.sh push [镜像仓库/项目]                  #
#   bash images.sh setimages [镜像仓库/项目] [名称空间]  #
# Example:                                               #
#   pull                                   拉取镜像      #
#   push reg.local:5000/wod/               推送镜像      #
#   setimages reg.local:5000/wod/ apaas    更新镜像      #
#                                                        #
##########################################################

            "
      break
    ;;
    esac
done

