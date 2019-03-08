function climax_watch
	set_color brwhite
    read -x -p 'echo set refresh interval: ' wait
    while true
        clear
        set_color white
        echo 'maxcoin' | figlet
        set_color normal
        climax_status
        sleep $wait
    end
end
# Defined in - @ line 2
function climax_stop
	if pidof maxcoind
        maxcoincmd stop >/dev/null ^/dev/null
        echo "Waiting for deamon to stop "
        set_color yellow
        while test (pidof maxcoind)
            echo -n .
            sleep 0.5
        end
    else
        echo "not running"
    end
    set_color normal
end
function climax_miners
	for miner in $climax_miners
        if ping -4 -c 1 -W 1 $miner >/dev/null ^/dev/null
            if netcat -z $miner 4068
                set miner_data (echo summary | netcat $miner 4068 ^ /dev/null | string split ';' | string match -r '=.*' | string trim -c '=')
                set pool (echo pool | netcat $miner 4068 ^ /dev/null | string split ';' | string match -r '=.*' | string trim -c '=')
                echo $miner $pool[1] - $miner_data[4] - $miner_data[6] KH/s, Accepted: $miner_data[8], Rejected $miner_data[9], Difficulty $miner_data[11], Up $miner_data[15] seconds
            else
                echo $miner not mining
            end
        else
            echo $miner offline
        end
        set -e miner_data
    end
end
function climax_message
	set message (curl -s "$BOTURL/sendMessage?parse_mode=markdown&chat_id=$climax_tgid&text=$argv" | jq .ok)
    if test $message != true
        echo "Problem sending message"
    end
end
# Defined in - @ line 2
function climax_run
	if not test -z (pidof maxcoind)
        echo "allready running, PID "(pidof maxcoind)
    else
        echo "Starting maxcoind"
        maxcoincmd -rpcallowip="172.16.*" -daemon -server >/dev/null ^/dev/null
        set_color magenta
        while not netcat -zv localhost 8668 >/dev/null ^/dev/null
            echo -n '.'
            sleep 0.1
        end
        set_color cyan
        while not maxcoincmd getinfo >/dev/null ^/dev/null
            echo -n '.'
            sleep 1
        end
        set_color normal
        echo "  ready"
    end
    #set_color brwhite
end
# Defined in - @ line 2
function climax_stats
	set info (maxcoincmd getinfo | jq '.balance,.blocks,.connections')
    set lastblock (maxcoincmd getblock (maxcoincmd getblockhash $info[2]) | jq .time)
    set timedif (math (date +%s) - $lastblock)
    if test $timedif -gt 86400
        echo -n Last block is (math $timedif / 86400) days old
    else if test $timedif -gt 3600
        echo -n Last block is (math $timedif / 3600) hours old
    else if test $timedif -gt 180
        echo -n Last block is (math $timedif / 60) minutes old
    else
        echo -n Last block is $timedif seconds old
    end
    echo ", 🖧 $info[3], @block $info[2], Δblocks  "(math $prevblockcount - $info[2])
    set -g prevblockcount $info[2]
end
# Defined in - @ line 2
function climax_sync
	if test -z (pidof maxcoind)
        climax_run
    else
        echo "maxcoind running"
    end
    while test (math (maxcoind getinfo | jq .blocks) - (curl -s https://explorer.maxcoinproject.net/api/getblockcount)) -lt 0
        climax_stats
        sleep 10
        tput el1
    end
    echo "blocks in sync"
end
function climax_wallet
	echo $argv
end
function climax_dbg
	curl -s $climax_connect --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"curltext\",\"method\":\"$argv\",\"params\":[]}" -H 'content-type:text/plain;'
    # | jq .result
end
function climax_rpc
	curl -s $climax_connect --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"curltext\",\"method\":\"$argv\",\"params\":[]}" -H 'content-type:text/plain;' | jq .result
end
# Defined in - @ line 2
function climax_archives
	set workdir ~/.maxcoin
    set resdir ~/bootstrap
    if not test -z (pidof maxcoind)
        echo "maxcoind should not be running for archive creation"
        return 1
    end
    rm -v $resdir/maxcoin_blocks.tgz
    echo ">>> Creating bootstrap.dat"
    rm -v $resdir/bootstrap.dat
    cat $workdir/blocks/blk*.dat >$resdir/bootstrap.dat
    ls -lh $resdir
    echo ">>> Creating SFXs"
    pushd $workdir
    rar u -as -x'*/LOG' -x'*/LOG.old' -x'*/LOCK' -sfx$resdir/win.sfx $resdir/maxcoin_blocks.exe blocks chainstate
    rar u -as -x'*/LOG' -x'*/LOG.old' -x'*/LOCK' -sfx$resdir/osx.sfx $resdir/maxcoin_blocks.sfx blocks chainstate
    rar c $resdir/maxcoin_blocks.exe <$resdir/exe_comment.txt
    rar c $resdir/maxcoin_blocks.sfx <$resdir/sfx_comment.txt
    echo ">>> Creating tgz"
    tar --create --gzip --file $resdir/maxcoin_blocks.tgz --exclude '*/LOG' --exclude '*/LOG.old' --exclude '*/LOCK' blocks chainstate
    echo ">>> Uploading to boostrap"
    popd
    rsync --progress --stats -h --inplace $resdir/bootstrap.dat $resdir/maxcoin_blocks.exe $resdir/maxcoin_blocks.sfx $resdir/maxcoin_blocks.tgz root@a.seed.maxcoinproject.net:
end
# Defined in - @ line 1
function climax_runtx
	if not test -z (pidof maxcoind)
        echo "allready running, PID "(pidof maxcoind)
    else
        echo "Starting maxcoind"
        maxcoincmd -rpcallowip="192.168.9.*" -daemon -server >/dev/null ^/dev/null
        set_color magenta
        while not netcat -zv localhost 8668 >/dev/null ^/dev/null
            echo -n '.'
            sleep 0.1
        end
        set_color cyan
        while not maxcoincmd getinfo >/dev/null ^/dev/null
            echo -n '.'
            sleep 1
        end
        set_color normal
        echo "  ready"
    end
    #set_color brwhite
end
# Defined in - @ line 2
function climax
	set datadir ~/.maxcoin
    set conf ~/.maxcoin/maxcoin.conf
    if not test -d $datadir
        echo "problem with datadir"
        return
    else if not test -f $conf
        echo "conf does not exist"
        return
    end
    alias maxcoincmd='maxcoind -datadir='$datadir' -conf='$conf
    if test -z $argv
        echo "Usage: start, run, stop, status, watch"
    end
    switch "$argv"
        case 'start'
            climax_run
            climax_watch
        case 'run'
            climax_run
        case 'stop'
            echo "Stopping maxcoind"
            climax_stop
        case 'status'
            climax_status
            climax_miners
        case 'watch'
            climax_watch
        case bootstrap
            climax_sync
            climax_stop
            climax_archives
        case '*'
            echo "what is "$argv" ?"
            echo "start (run & watch), run, watch, status, bootstrap"
    end
end
function climax_status
	if test -z (pidof maxcoind)
        echo maxcoind not running
    else
        set info (maxcoincmd getinfo | jq '.balance,.blocks,.connections')
        set lastblock (maxcoincmd getblock (maxcoincmd getblockhash $info[2]) | jq .time)
        set timedif (math (date +%s) - $lastblock)
        if test $timedif -gt 86400
            echo -n Last block is (math $timedif / 86400) days old
        else if test $timedif -gt 3600
            echo -n Last block is (math $timedif / 3600) hours old
        else if test $timedif -gt 180
            echo -n Last block is (math $timedif / 60) minutes old
        else
            echo -n Last block is $timedif seconds old
        end
        echo " - "(date -d @$lastblock)
        echo Balance is $info[1]
        echo Connections: $info[3]
        echo Difficulty: (maxcoincmd getdifficulty | numfmt --to=si)
        echo Block Hashrate: (maxcoincmd getnetworkhashps | numfmt --to=si)
        echo Blocks: $info[2]
    end
end
funcsave climax_watch
funcsave climax_stop
funcsave climax_miners
funcsave climax_message
funcsave climax_run
funcsave climax_stats
funcsave climax_sync
funcsave climax_wallet
funcsave climax_dbg
funcsave climax_rpc
funcsave climax_archives
funcsave climax_runtx
funcsave climax
funcsave climax_status
