#!/bin/bash
#Moordrik the Wizard
#Also known as Moordrik the Vast
#1.0

#wizard	install /opt/outernet /install/ModuleName.manifest 

#Version of the Wizard. To prevent old or mismatched manifests running. 
ARCANE_TALENT=1

#Collects the logged in users home file path. 
ORIGINAL_USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)


# Check if the script is being run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo."
    exit 1
 fi



function checkManifest() {
    # Ensure we actually got a path passed to the function
    local manifest_path="$1"
    
    if [ -z "$manifest_path" ]; then
        echo "Wizard Error: No manifest path provided to checkManifest."
        exit 1
    fi
    
    if [ ! -f "$manifest_path" ]; then
        echo "Wizard Error: Manifest file '$manifest_path' not found."
        exit 1
    fi
    
    # Source the file to bring variables into global scope
    source "$manifest_path"

    # Correct arithmetic comparison
    if (( ARCANE_VERSION != ARCANE_TALENT )); then
        echo "Wizard Error: Manifest version: $ARCANE_VERSION does not match Wizard: $ARCANE_TALENT."
        exit 1
    fi

    echo "Wiz: Manifest ${MODULE_NAME} Loaded."
}



# ==============	Bash	 ============== #
function modBash() {
	echo "--Bash Scripts	${1}	Found: ${#EXECUTABLE_SCRIPTS[@]}."
	
	case "$1" in
	
	"install" )
		if [ ${#EXECUTABLE_SCRIPTS[@]} -gt 0 ]; then
			for script in "${EXECUTABLE_SCRIPTS[@]}"; do	    
				if cp -f "${INSTALL_LOCATION}/bash/$script" "/usr/local/bin/"; then
				  chmod +x /usr/local/bin/"$script"
				else
				  echo "Error: Service Scripts could not be moved."
				  exit 1
				fi
			    echo "	-${script} :successful."
			done
		fi
	  ;;

	"uninstall" )
		for script in "${EXECUTABLE_SCRIPTS[@]}"; do
			if rm /usr/local/bin/${script}; then
				echo "${script}' removed successfully."
			else
			 	echo "Error: Script ${script} could not be removed."
			fi
		done
	;;
	
	  "validate" )
		if [ ${#EXECUTABLE_SCRIPTS[@]} -gt 0 ]; then 
			for script in "${EXECUTABLE_SCRIPTS[@]}"; do	    
				echo "	-${script}"
			done
		fi
	  ;;
	esac
}



# ==============	Services	============== #
function modServices() {
	echo "--Services	${1}	Found: ${#SYSTEMD_SERVICES[@]}.	"
	
	case "$1" in
	
		"install" )
			if [ ${#SYSTEMD_SERVICES[@]} -gt 0 ]; then
				for service in "${SYSTEMD_SERVICES[@]}"; do
					if cp -f "${INSTALL_LOCATION}/services/${service}" "/etc/systemd/system/"; then
						echo "${service}" >> /dev/null
					else
					  echo "Error: Service $service could not be moved."
					  exit 1
					fi
					echo "	-${service} :successful."
				done
			fi
		  ;;
	
		"uninstall" )
			
			for service in "${SYSTEMD_SERVICES[@]}"; do
				if rm /etc/systemd/system/${service}; then
		  			echo "${service}" >> /dev/null
				else
				  echo "Error: Service $service could not be removed."
				fi
		  		echo "	-${service} removed successfully."
			done
		;;
		
		"vaidate" )
			echo "Debug Service PI"
			if [ ${#SYSTEMD_SERVICES[@]} -gt 0 ]; then
			echo "Debug Service PO"
				for service in "${SYSTEMD_SERVICES[@]}"; do
			  		echo "	-${service}"
				done
			fi
		;;

	esac
}




# ==============	MoveFiles	============== #
function modMoveFiles() {
	echo "--Move Files	${1}	Found: ${#FILES_TO_MOVE[@]}.	"
	
	case "$1" in
	
		"install" )
			if [ ${#FILES_TO_MOVE[@]} -gt 0 ]; then
				
				for source_path in "${!FILES_TO_MOVE[@]}"; do
				    destination_path="${FILES_TO_MOVE[$source_path]}"
				 	home_path="${INSTALL_LOCATION}${source_path}"
					
				    # Ensure the destination directory exists
				    mkdir -p "$destination_path"
				
				    # Check if the source is a directory
				    if [ -d "${home_path}" ]; then
				        # Use `cp -r` to copy the directory and its contents recursively
				        cp -r "${home_path}" "$destination_path"
					 	echo "	dir-$home_path: successful"
				        
				    # Check if the source is a file
				    elif [ -f "${home_path}" ]; then
				        # Use `cp` to copy the single file
				        cp "${home_path}" "$destination_path"
					 	echo "	file-$home_path: successful"
						
				    else
				        echo "Warning: Source path '${home_path}' is neither a file nor a directory. Skipping."
					 	exit 1
				    fi
				done
			fi
		;;
	
		"uninstall" )
			for source_path in "${!FILES_TO_MOVE[@]}"; do
		
				destination_path="${FILES_TO_MOVE[$source_path]}"
				INSTALLED_FILE_PATH=${destination_path}/$(basename "${source_path}") 
					
				echo "  -Processing: ${INSTALLED_FILE_PATH}"
			
				# Check if the source is a directory
				if [ -d "${INSTALLED_FILE_PATH}" ]; then
					rm ${INSTALLED_FILE_PATH} -r	        
				# Check if the source is a file
				elif [ -f "${INSTALLED_FILE_PATH}" ]; then
					rm ${INSTALLED_FILE_PATH}
				else
					echo "Warning: Source path '${INSTALLED_FILE_PATH}' is neither a file nor a directory. Skipping."
				fi
				done

			  
		;;
		
		"vaidate" )
			
			if [ ${#FILES_TO_MOVE[@]} -gt 0 ]; then
	
				for source_path in "${!FILES_TO_MOVE[@]}"; do
				    destination_path="${FILES_TO_MOVE[$source_path]}"
				 	home_path="${INSTALL_LOCATION}${source_path}"
							
				    # Check if the source is a directory
				    if [ -d "${home_path}" ]; then
					 	echo "	dir-$home_path"
				        
				    # Check if the source is a file
				    elif [ -f "${home_path}" ]; then
					 	echo "	file-$home_path"
						
				    else
				        echo "Warning: Source path '${home_path}' is neither a file nor a directory."
					 	exit 1
				    fi
				done
			fi
		;;

	esac
}



# ==============	Link	 ============== #
function modSymLink() {
	echo "--Link Files:	${1}	Found: ${#FILES_TO_LINK[@]}.	"
	
	case "$1" in
	
	"install" )
		
		if [ ${#FILES_TO_LINK[@]} -gt 0 ]; then
			echo "--Creating Symbolic Links"
			for working_source_path in "${!FILES_TO_LINK[@]}"; do
		
				file_name=$(basename "$working_source_path")
				destination_path="${FILES_TO_LINK[$working_source_path]}"
				file_destination_path="${destination_path}${file_name}"
				
				mkdir -p "$destination_path"
		
				# --- Check for idempotence: remove old links first ---
				if [ -L "$file_destination_path" ] || [ -f "$file_destination_path" ] || [ -d "$file_destination_path" ]; then
					echo "  -> Removing existing file/link at: ${file_destination_path}"
					rm -rf "$file_destination_path"
				fi
		
				# Check if the source is a directory
				if [ -d "${working_source_path}" ]; then
					ln -s "${working_source_path}" "${file_destination_path}"
					echo "  -> Directory link created: ${working_source_path} -> ${file_destination_path}"
					
				# Check if the source is a file
				elif [ -f "${working_source_path}" ]; then
					ln -s "${working_source_path}" "${file_destination_path}"
					echo "  -> File link created: ${working_source_path} -> ${file_destination_path}"
					
				else
					echo "Warning: Source path '${working_source_path}' is neither a file nor a directory. Skipping."
					# This will exit the script with an error code.
					exit 1
				fi
			done
		fi
	;;

	"uninstall" )
	  	
		echo "Warning: Removing linked files not supported by wizard at this version"
	;;
	
	"validate" )
		
		if [ ${#FILES_TO_LINK[@]} -gt 0 ]; then
			for working_source_path in "${!FILES_TO_LINK[@]}"; do
		
				file_name=$(basename "$working_source_path")
				destination_path="${FILES_TO_LINK[$working_source_path]}"
				file_destination_path="${destination_path}${file_name}"
		
				# Check if the source is a directory
				if [ -d "${working_source_path}" ]; then
					echo " 	-> Directory link: ${working_source_path} -> ${file_destination_path}"
					
				# Check if the source is a file
				elif [ -f "${working_source_path}" ]; then
					echo "  -> File link: ${working_source_path} -> ${working_source_path}"
					
				else
					echo "Warning: Source path '${working_source_path}' is neither a file nor a directory. Skipping."
					# This will exit the script with an error code.
					exit 1
				fi
			done
		fi
	;;
	esac
}



# ==============	Cleanup	 ============== #
function modCleanup() {
	echo "--Clean Files:	${1}	Found: ${#FILES_TO_CLEANUP[@]}.	"
	
	case "$1" in
	
	"install" )
		
		if [ ${#FILES_TO_CLEANUP[@]} -gt 0 ]; then 
		echo "--Cleaning up"
			for cleanfiles in "${FILES_TO_CLEANUP[@]}"; do	    
				
		  	    # Check if the source is a directory
			    if [ -d "${cleanfiles}" ]; then
			      	rm "${cleanfiles}" -rf
				 	echo "	dir-$cleanfiles: successful"
			        
			    # Check if the source is a file
			    elif [ -f "${cleanfiles}" ]; then
					rm "${cleanfiles}" 
				 	echo "	file-$cleanfiles: successful"
		  		else
				  echo "Error: Removing ${cleanfiles}."
				fi
				
			    echo "	-${cleanfiles} :successful."
			done
		fi
	;;

	"uninstall" )
	  	
		if [ ${#FILES_TO_CLEANUP[@]} -gt 0 ]; then 
			echo "--Cleaning up"
			for cleanfiles in "${FILES_TO_CLEANUP[@]}"; do	    
				
				# Check if the source is a directory
				if [ -d "${cleanfiles}" ]; then
					rm "${cleanfiles}" 
					echo "	dir-$cleanfiles: successful"
					
				# Check if the source is a file
				elif [ -f "${cleanfiles}" ]; then
					rm "${cleanfiles}" 
					echo "	file-$cleanfiles: successful"
				else
				  echo "Error: Removing ${cleanfiles}."
				fi
				
			echo "	-${cleanfiles} :successful."
			done
		fi
		exit 0 
	;;
	
	"validate" )
		
		if [ ${#FILES_TO_CLEANUP[@]} -gt 0 ]; then 
		
			for cleanfiles in "${FILES_TO_CLEANUP[@]}"; do	    
				
		  	    # Check if the source is a directory
			    if [ -d "${cleanfiles}" ]; then
				 	echo "	dir-$cleanfiles"
			        
			    # Check if the source is a file
			    elif [ -f "${cleanfiles}" ]; then
				 	echo "	file-$cleanfiles"
		  		else
				  echo "Error: Removing ${cleanfiles}."
				fi
			done
		fi
	;;
	
esac
}





# ==============	Executable	 ============== #
function modExecutable() {
	echo "--Executable:	${1}	Found: .	"
	
	case "$1" in
	
	"install" )
		
				echo "Not Supported in this version"
		
	;;

	"uninstall" )
	  	
				echo "Not Supported in this version"
	;;
	
	"validate" )
		echo ""
				echo "Not Supported in this version"
	;;
	
esac
}




# ==============	Create Dir	 ============== #
function modMakeDir() {
	echo "--Create Dir:	${1}	Found: .	"
	
	case "$1" in
	
	"install" )
		
				echo "Not Supported in this version"
		
	;;

	"uninstall" )
	  	
				echo "Not Supported in this version"
	;;
	
	"validate" )
		echo ""
				echo "Not Supported in this version"
	;;
	
esac
}


#--== MAIN ==--#
#Starts Main
case "$1" in

  "install" )
	#2 Repository Location
	#3 Manifest Location
  	checkManifest ${3}

	echo "Starting install of: $MODULE_NAME"

	INSTALL_LOCATION="${2}${BASE_FILEPATH}"
	echo "debug: Install Location: ${INSTALL_LOCATION}"
    echo
 	echo "Wiz: Install Complete"
    exit 0
  ;;




	"uninstall" )
		echo "Wiz: Uninstalling Manifest"
		
		checkManifest ${2}
		
	    echo "uninstalling: $MODULE_NAME"
		exit 0
	;;


	
	"validate" )
		echo "Wiz: Validateing Manifest"
		
		checkManifest ${2}
		
		echo
		echo "Arcane Version: ${ARCANE_VERSION}"
		echo "Manifest Version: ${MANIFEST_VERSION}"
		echo "Module Name: ${MODULE_NAME}"
		echo "Resource Filepath: ${BASE_FILEPATH}"
		echo 
		modBash ${1}
		modServices ${1}
		modMoveFiles ${1}
		modSymLink ${1}
		modCleanup ${1}
		modExecutable ${1}
		modMakeDir ${1}
	 	exit 0
	;;



	"version" )
		echo ${ARCANE_TALENT}
	;;


	"help" )
		echo "install <Base Repo Location> <Manifest File Location>"
		echo "install <Base Repo Location> <Manifest File Location>"
		echo "validate <Manifest File Location>"
		echo "version"
		echo "help"
		echo
		echo "--Exsamples: install ~/MyPackage ~/MyPackage/install/MyPackage.manifest"
	;;


	*) 
	echo "Invalid options: $1, $2. use option help to see more options"
	;;

esac
