// initialize.ck


// Load custom classes
Machine.add(me.dir()+"/BPM.ck");

// Load recording script
Machine.add(me.dir()+"/rec-audio-stereo.ck");

// Load follower script
Machine.add(me.dir()+"/follower-hypno.ck");

/*
Usage: 

1. Put all four scripts into the same folder
2. Open rec-audio-stereo.ck in a text editor
   and change line 13 to the prefix you want 
   to use.
3. Run miniAudicle (or ChucK by itself)
4. Run initialize.ck
5. Start talking
6. Remove the shreds or stop the virtual machine when done.
   The recording script will create a time-stamped WAV file.
*/