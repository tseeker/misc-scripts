#!/bin/bash
(

. /etc/router-checks.conf

exec >>$LOG_FILE 2>&1
date
echo "... STARTING"
. "$LIB_DIR/pings"

echo $$ > $PID_FILE
stop_file="$PID_FILE.$$"
trap "rm -f $stop_file" SIGINT SIGTERM
touch $stop_file
SLEEP_TIME=60
while [ -f "$stop_file" ]; do
	sleep $SLEEP_TIME
	SLEEP_TIME=1

	pr_switch=`mktemp`
	pr_peer=`mktemp`
	if [ -f "$ACTIVATION_FILE" ]; then

		# When the secondary router is active, disable it if the
		# internet is not reachable and either the primary router is
		# up or the switch is down

		pr_internet=`mktemp`
		wait_pings `try_ping $INTERNET_ADDR $pr_internet` \
			`try_ping $PRIMARY_ADDR $pr_peer` \
			`try_ping $SWITCH_ADDR $pr_switch`
		if [ -f "$pr_internet" ]; then
			if [ -f "$pr_switch" ] || ! [ -f "$pr_peer" ]; then
				date
				echo "de-activating connection"
				$LIB_DIR/deactivate.sh
				rm -f "$ACTIVATION_FILE"
				SLEEP_TIME=10
			fi
		fi
		rm -f "$pr_internet"

	else

		# When the secondary router is inactive, enable it if the
		# switch is up and both the primary router and the main address
		# are unreachable

		pr_main=`mktemp`
		wait_pings `try_ping $SWITCH_ADDR $pr_switch` \
			`try_ping $PRIMARY_ADDR $pr_peer` \
			`try_ping $MAIN_ADDR $pr_main`
		if [ -f "$pr_main" ] && [ -f "$pr_peer" ] && ! [ -f "$pr_switch" ]; then
			date
			echo "activating connection"
			$LIB_DIR/activate.sh
			touch "$ACTIVATION_FILE"
			SLEEP_TIME=20
		fi
		rm -f "$pr_main"

	fi
	rm -f  "$pr_peer" "$pr_switch"
done
if [ -f "$ACTIVATION_FILE" ]; then
	$LIB_DIR/deactivate.sh
	rm -f "$ACTIVATION_FILE"
fi
date
echo "... EXITING"
rm "$PID_FILE"

) &
