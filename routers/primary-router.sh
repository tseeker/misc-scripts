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
	if [ -f "$ACTIVATION_FILE" ]; then

		# When the primary router is active, disable it if the switch
		# is off-line

		wait_pings `try_ping $SWITCH_ADDR $pr_switch`
		if [ -f "$pr_switch" ]; then
			date
			echo "de-activating connection"
			$LIB_DIR/deactivate.sh
			rm -f "$ACTIVATION_FILE"
			SLEEP_TIME=10
		fi

	else

		# When the primary router is inactive, enable it if the switch
		# is up and the main router IP does not exist

		pr_main=`mktemp`
		wait_pings `try_ping $SWITCH_ADDR $pr_switch` \
			`try_ping $MAIN_ADDR $pr_main`
		if [ -f "$pr_main" ] && ! [ -f "$pr_switch" ]; then
			date
			echo "activating connection"
			$LIB_DIR/activate.sh
			touch "$ACTIVATION_FILE"
			SLEEP_TIME=20
		fi
		rm -f "$pr_main"

	fi
	rm -f "$pr_switch"
done
if [ -f "$ACTIVATION_FILE" ]; then
	$LIB_DIR/deactivate.sh
	rm -f "$ACTIVATION_FILE"
fi
date
echo "... EXITING"
rm "$PID_FILE"

) &
