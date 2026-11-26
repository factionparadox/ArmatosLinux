# Armatos voice library — source this from bash.
#
#   . /usr/lib/armatos/voice.sh
#   vox ready            # prints the line for "ready" in the chosen language
#   vox_say ready        # same, but only when stdout is a terminal
#
# Language: ~/.config/armatos/lingua, then /etc/armatos/lingua, then Latin.
# Each file holds one word: "la" or "en". ARMATOS_LINGUA overrides both.
# Scripts and pipes never see the voice: vox_say is silent off a terminal.

armatos_lingua() {
	local l="${ARMATOS_LINGUA:-}"
	if [ -z "$l" ] && [ -n "${HOME:-}" ] && [ -r "$HOME/.config/armatos/lingua" ]; then
		read -r l < "$HOME/.config/armatos/lingua"
	fi
	if [ -z "$l" ] && [ -r /etc/armatos/lingua ]; then
		read -r l < /etc/armatos/lingua
	fi
	case "$l" in en) echo en ;; *) echo la ;; esac
}

# vox KEY [ARG...] — ARGs fill %s placeholders.
vox() {
	local key="$1"; shift
	local la en
	case "$key" in
		ave)        la="Ave, Imperator."; en="Hail, Imperator." ;;
		ready)      la="Ave, Imperator. Legio parata est. Quid imperas?"
		            en="Hail, Imperator. The legion stands ready. Your orders?" ;;
		done)       la="Factum est."; en="It is done." ;;
		done_time)  la="Factum est. (%s)"; en="It is done. (%s)" ;;
		failed)     la="Iussum defecit, Imperator (%s)."; en="The order failed, Imperator (%s)." ;;
		haruspex)   la="Arcessamne haruspicem? → haruspex"; en="Shall I summon the haruspex? → haruspex" ;;
		unknown)    la="Nemo miles hoc nomine respondet: %s"; en="No soldier answers to that name: %s" ;;
		vale)       la="Vale, Imperator."; en="Farewell, Imperator." ;;
		senate)     la="Auctoritas Senatus quaeritur. Tessera (%s): "
		            en="Seeking the Senate's authority. Watchword (%s): " ;;
		senate_no)  la="Senatus petitionem tuam negat."; en="The Senate denies your petition." ;;
		march)      la="Iter incipit: %s"; en="The march begins: %s" ;;
		tribute)    la="Tributum e provinciis advenit."; en="Tribute has arrived from the provinces." ;;
		no_tribute) la="Nullum tributum. Imperium integrum est."; en="No tribute due. The Empire is whole." ;;
		snap)       la="Memoria servata: %s"; en="Memory preserved: %s" ;;
		damned)     la="Damnatio memoriae: %s"; en="Memory condemned: %s" ;;
		restored)   la="Restitutum est. Iterum incipe ut perficias."
		            en="Restored. Restart to complete it." ;;
		no_btrfs)   la="Radix non est Btrfs; damnatio otiosa est."
		            en="Root isn't Btrfs; damnatio has nothing to do." ;;
		sacred)     la="Ignis Vestae ardet: %s"; en="Vesta's flame burns: %s" ;;
		*)          la="$key"; en="$key" ;;
	esac
	local fmt
	if [ "$(armatos_lingua)" = en ]; then fmt="$en"; else fmt="$la"; fi
	# shellcheck disable=SC2059
	printf "$fmt\n" "$@"
}

vox_say() {
	[ -t 1 ] || return 0
	[ "${ARMATOS_VOX:-1}" = 0 ] && return 0
	vox "$@"
}

# Gold for the Imperator, red for alerts. Plain when not a terminal.
if [ -t 1 ]; then
	ARMATOS_GOLD=$'\e[38;5;178m'; ARMATOS_RED=$'\e[38;5;124m'; ARMATOS_RESET=$'\e[0m'
else
	ARMATOS_GOLD=; ARMATOS_RED=; ARMATOS_RESET=
fi
