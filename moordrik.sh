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

	MANIFEST_LOCATION = ${1}
   	
 	if [ ! -f "$MANIFEST_LOCATION" ]; then
	    echo "Wizard Error: Manifest file '$MANIFEST_LOCATION' not found. Exiting."
	    exit 1
	fi
	
  	source $MANIFEST_LOCATION

	if (( $[ARCANE_VERSION] != ${ARCANE_TALENT} )); then
		echo "Wizard Error: Manifest version: $ARCANE_VERSION does not match Wizard version: $ARCANE_TALENT. Halting."
	    exit 1
	fi

	echo "Wiz: Manifest ${MODULE_NAME} Loaded."
	
}

#Starts Main
case "$1" in

  "install" )
	#2 Repository Location
	#3 Manifest Location
  	checkManifest ${3}
  
	
	checkManifest
    echo "Starting install of: $MODULE_NAME"

	INSTALL_LOCATION="${2}${BASE_FILEPATH}"
	echo "debug: Install Location: ${INSTALL_LOCATION}"
    echo

	echo "Number of Scripts: ${#EXECUTABLE_SCRIPTS[@]}"
	
	if [ ${#EXECUTABLE_SCRIPTS[@]} -gt 0 ]; then
		echo "--Installing Bash Scripts"
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

 
	if [ ${#SYSTEMD_SERVICES[@]} -gt 0 ]; then
		echo "--Installing services"
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


	if [ ${#FILES_TO_MOVE[@]} -gt 0 ]; then
		echo "--Installing files"
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

 	echo "Wiz: Install Complete"
    exit 0
  ;;




	"uninstall" )
	
	  	MANIFEST_LOCATION="${2}${3}"
		checkManifest
	    echo "uninstalling: $MODULE_NAME"
	
		echo "Removing Scripts"
		for script in "${EXECUTABLE_SCRIPTS[@]}"; do
			if rm /usr/local/bin/${script}; then
				echo "${script}' removed successfully."
			else
			 	echo "Error: Script ${script} could not be removed."
			fi
		done
	
		echo "Removing Services"
		for service in "${SYSTEMD_SERVICES[@]}"; do
			if rm /etc/systemd/system/${service}; then
	  			echo "${service}" >> /dev/null
			else
			  echo "Error: Service $service could not be removed."
			fi
	  		echo "	-${service} removed successfully."
		done
	
	
	
	
	   
			echo "Removing files"
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
		echo "Wiz: Validateing Manifest"
		
		checkManifest ${1}
		echo
		echo "Arcane Version: ${ARCANE_VERSION}"
		echo "Manifest Version: ${MANIFEST_VERSION}"
		echo "Module Name: ${MODULE_NAME}"
		echo "Resource Filepath: ${BASE_FILEPATH}"
		echo 
		
		echo "--Bash Scripts: 		Found: ${#EXECUTABLE_SCRIPTS[@]}"
		if [ ${#EXECUTABLE_SCRIPTS[@]} -gt 0 ]; then 
			for script in "${EXECUTABLE_SCRIPTS[@]}"; do	    
			    echo "	-${script}"
			done
		fi

		echo "--System Services: 		Found: ${#SYSTEMD_SERVICES[@]}"	 
		if [ ${#SYSTEMD_SERVICES[@]} -gt 0 ]; then
			for service in "${SYSTEMD_SERVICES[@]}"; do
		  		echo "	-${service}"
			done
		fi
	
		echo "--Files:			Found: ${#FILES_TO_MOVE[@]}"	
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
	
		echo "--Symbolic Links:		Found: ${#FILES_TO_LINK[@]}"
		if [ ${#FILES_TO_LINK[@]} -gt 0 ]; then
			for working_source_path in "${!FILES_TO_LINK[@]}"; do
		
				file_name=$(basename "$working_source_path")
				destination_path="${FILES_TO_LINK[$working_source_path]}"
				file_destination_path="${destination_path}${file_name}"
		
				# Check if the source is a directory
				if [ -d "${working_source_path}" ]; then
					echo "  -> Directory link: ${working_source_path} -> ${file_destination_path}"
					
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

	echo "--Cleaning: 			Found: ${#FILES_TO_CLEANUP[@]}"
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

 	echo "Wiz: End"
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
