#!/bin/bash
#
# Fancy Module - Aesthetics installs and configs
#

MS_FONTS_VERSION="2.6-1"

FONTS_DNF_LIST=(
	mozilla-fira-fonts-common
	mozilla-fira-mono-fonts
	mozilla-fira-sans-fonts
	mozilla-zilla-slab-fonts-common
	mozilla-zilla-slab-highlight-fonts
	google-noto-serif-fonts
	google-noto-sans-symbols-fonts
	google-noto-sans-symbols2-fonts
	google-noto-sans-mono-fonts
	google-noto-sans-fonts
	google-noto-emoji-fonts
	google-noto-color-emoji-fonts
	google-noto-fonts-common
	google-go-smallcaps-fonts
	google-go-mono-fonts
	google-go-fonts
	google-carlito-fonts
	redhat-text-fonts
	redhat-mono-fonts
	redhat-display-fonts
	google-droid-fonts-all
	google-arimo-fonts
	google-roboto-fonts
	google-roboto-mono-fonts
	google-roboto-slab-fonts
	rsms-inter-fonts
	adobe-source-code-pro-fonts
	msttcore-fonts-installer
	bitstream-vera-sans-fonts
	bitstream-vera-sans-mono-fonts
	bitstream-vera-serif-fonts
	comic-neue-angular-fonts
	comic-neue-fonts
	comic-neue-web-fonts
	fontawesome-6-brands-fonts
	fontawesome-6-free-fonts
	fontawesome-fonts-web
	ibm-plex-sans-fonts
	ibm-plex-serif-fonts
	lato-fonts
	material-icons-fonts
	powerline-fonts
)

FONTS_NERD_LIST=(
    CascadiaCode
    CascadiaMono
    Cousine
    FiraCode
    FiraMono
    Hack
    iA-Writer
    IBMPlexMono
    Inconsolata
    Iosevka
    IosevkaTerm
    IosevkaTermSlab
    JetBrainsMono
    LiberationMono
    Meslo
    SourceCodePro
    UbuntuMono
    Ubuntu
)

FONTS_URLS_LIST=(
	https://www.omnibus-type.com/wp-content/uploads/Asap.zip
	https://www.omnibus-type.com/wp-content/uploads/Asap-Condensed.zip
	https://www.omnibus-type.com/wp-content/uploads/Archivo.zip
	https://www.omnibus-type.com/wp-content/uploads/Archivo-Narrow.zip
)

ICONS_LIST=(
	papirus-icon-theme
	flat-remix-icon-theme
	la-capitaine-icon-theme
	luv-icon-theme
	pop-icon-theme
)

WALLS_FOLDERS=(
	"tile"
	"retro"
	"radium"
	"nord"
	"mountain"
	"monochrome"
	"digital"
)

execute_fancy_module() {
	log_subheader "System install and config aesthetics"
	install_dnf_fonts
	install_nerd_fonts
	install_urls_fonts
	install_icons
	install_wallpapers
    log_success "Fancy aesthetics module completed successfully"
    return 0
}


function install_dnf_fonts(){
	log_info "Installing preferred fonts from DNF"

	if [ ! ${#FONTS_DNF_LIST[@]} -eq 0 ]; then
	    log_info "List of fonts that will be installed: \n\n$(echo "${FONTS_DNF_LIST[@]}" | tr ' ' '\n')\n"
	    mkdir -p "/tmp/fonts/"
	    log_info "Installing DNF Fonts:"

   	    for FONT in "${FONTS_DNF_LIST[@]}"; do
	    	if [[ $FONT != "" ]] && [[ $FONT != "#"* ]]; then

				log_info "Downloading and installing font '$FONT'..."
				superuser_do "dnf install -y --skip-broken $FONT"
				if [ $? -ne 0 ]; then
					log_failed "Error installing font '$FONT'."
				else
					log_success "Font '$FONT' was installed."
				fi

	    	fi
	    done
	else
		log_warning "The list of DNF fonts is empty. Moving on..."
	fi

    log_info "Updating font cache..."
	fc-cache -f
	log_success "Preferred DNF fonts installation complete."
}

function install_nerd_fonts(){
	log_info "Installing preferred fonts"
	local FONT_URL_DL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

	if [ ! ${#FONTS_NERD_LIST[@]} -eq 0 ]; then
	    log_info "List of fonts that will be installed: \n\n$(echo "${FONTS_NERD_LIST[@]}" | tr ' ' '\n')\n"
	    mkdir -p "/tmp/fonts/"
	    log_info "Installing Nerd Fonts:"

   	    for FONT in "${FONTS_NERD_LIST[@]}"; do
	    	if [[ $FONT != "" ]] && [[ $FONT != "#"* ]]; then
	    		if [ -d "$FONTS_DOTS_DIR/$FONT/" ] && [ "$(ls -A "$FONTS_DOTS_DIR/$FONT/")" ]; then
	    			log_info "The font '$FONT' already exists. Skipping download..."
	    		else
	    			log_info "Downloading and installing font '$FONT'..."
	    			curl -L --progress-bar -o "/tmp/fonts/$FONT.zip" "$FONT_URL_DL/$FONT.zip"
	    			if [ $? -ne 0 ]; then
	        			log_failed "Error downloading font '$FONT'."
	        		else
	        			mkdir -p "$FONTS_DOTS_DIR/$FONT/"
	        			log_info "Extract font '$FONT' in '$FONTS_DOTS_DIR/$FONT/'..."
	        			unzip -qq -o "/tmp/fonts/$FONT.zip" -d "$FONTS_DOTS_DIR/$FONT/"
	        			log_success "Font '$FONT' was installed."
	        		fi
	    		fi
	    	fi
	    done
	else
		log_warning "The list of fonts is empty. Moving on..."
	fi

    log_info "Updating font cache..."
	fc-cache -f
	log_success "Preferred Nerd fonts installation complete."
}

function install_urls_fonts(){
	log_info "Installing preferred fonts from sites"

	if [ ! ${#FONTS_URLS_LIST[@]} -eq 0 ]; then
	    info "List of URLs where the fonts will be downloaded: \n\n$(echo "${FONTS_URLS_LIST[@]}" | tr ' ' '\n')\n"
	    mkdir -p "/tmp/fonts/"
	    log_info "Installing Fonts:"

   	    for FONT in "${FONTS_URLS_LIST[@]}"; do
			FONTNAME=$(basename "$FONT" .zip)
	    	if [[ $FONT != "" ]] && [[ $FONT != "#"* ]]; then
	    		if [ -d "$FONTS_DOTS_DIR/$FONTNAME/" ] && [ "$(ls -A "$FONTS_DOTS_DIR/$FONTNAME/")" ]; then
	    			log_info "The font '$FONTNAME' already exists. Skipping download..."
	    		else
	    			log_info "Downloading and installing font '$FONTNAME'..."
					curl -L --progress-bar -o "/tmp/fonts/$FONTNAME.zip" "$FONT"

	    			if [ $? -ne 0 ]; then
	        			log_failed "Error downloading font '$FONTNAME'."
	        		else
	        			mkdir -p "$FONTS_DOTS_DIR/$FONTNAME/"
	        			log_info "Extract font '$FONT' in '$FONTS_DOTS_DIR/$FONTNAME/'..."
	        			unzip -qq -o "/tmp/fonts/$FONTNAME.zip" -d "$FONTS_DOTS_DIR/$FONTNAME/"
	        			log_success "Font '$FONTNAME' was installed."
	        		fi
	    		fi
	    	fi
	    done
	else
		log_warning "The list of fonts is empty. Moving on..."
	fi

    log_info "Updating font cache..."
	fc-cache -f
	log_success "Preferred fonts from sites installation complete."
}

function install_icons() {
	install_from_array "preferred icons" "${ICONS_FAVORITES_LIST[@]}"
}


function install_wallpapers() {
	log_info "Installing wallpapers"
	local COLLECTION_WALLS="$WALLPAPERS_DIR/collection"
	local WALLS_REPO_URL="https://github.com/lucasbt/walls"
	local TEMP_DIR="/tmp/walls"

	if [ -d "$COLLECTION_WALLS" ] && [ "$(ls -A "$COLLECTION_WALLS/")" ]; then
    	log_info "Wallpapers collection already exists. Skipping download..."
	else
		mkdir -p $COLLECTION_WALLS
        if ask_yes_no "ATTENTION! The download content may be very large. \nProceed with download?" "y"; then
			git clone --filter=blob:none --no-checkout "$WALLS_REPO_URL" "$TEMP_DIR"
			cd "$TEMP_DIR" || return 0
			git sparse-checkout init --cone
			log_info "Download wallpapers folders to '$COLLECTION_WALLS'..."
			for FOLDER in "${WALLS_FOLDERS[@]}"; do
				log_info "Download folder '$FOLDER'..."
				git sparse-checkout set "$FOLDER"  # Define a pasta a ser baixada
				git checkout HEAD  # Garante que os arquivos sejam baixados
				# Move a pasta para o diretório de destino desejado
				mv "$FOLDER" "$COLLECTION_WALLS"
			done
			cd - > /dev/null 2>&1
        else
			log_warning "Skip download of wallpapers..."
		fi
	fi
}