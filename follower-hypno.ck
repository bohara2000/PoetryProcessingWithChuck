/*---------------------------------------------------------------------------
    S.M.E.L.T. : Small Musically Expressive Laptop Toolkit

    Copyright (c) 2007 Rebecca Fiebrink and Ge Wang.  All rights reserved.
      http://smelt.cs.princeton.edu/
      http://soundlab.cs.princeton.edu/

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
    U.S.A.
-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// name: follower-hypno.ck
// desc: simple (but effective) envelope follower baqsed on 
//       code by Perry Cook.
//
// Perry's comments:
/* Hi all.  I keep meaning to post to this list about the under-exploited
feature that all unit generators have, in that you can cause their inputs
to multiply rather than add.  As an example, here's a simple power
envelope follower that doesn't require sample-level chuck intervention.  A
gain UG is used to square the incoming A/D signal (try it on your built-in
mic), then a OnePole UG is used as a "leaky integrator" to keep a running
estimate of the signal power. The main loop wakes up each 100 ms and
checks the power, and prints out a message if it's over a certain level. 
You might need to change the threshold, but you get the idea. */
//
// author: Perry Cook
// commented by: Rebecca Fiebrink and Ge Wang
// additional comments by: Bryant O'Hara
//
// to run (in command line chuck):
//     %> chuck initialize.ck
//
// to run (in miniAudicle):
//     (make sure VM is started, add the thing)
//-----------------------------------------------------------------------------


// patch
adc => Gain g => OnePole p => blackhole;
// square the input, by chucking adc to g a second time
adc => g;
// set g to multiply its inputs
3 => g.op;

// patch audio to dac as well
adc => Gain g2 => dac;
1.2 => g2.gain;


// threshold
0.25  => float threshold;
// set pole position, influences how closely the envelope follows the input
//   : pole = 0 -> output == input; 
//   : as pole position approaches 1, follower will respond more slowly to input
0.999 => p.pole;

// time before which to not check for threshold
time notBefore;

// (BKO) Set global tempo
BPM bpm;
bpm.tempo(60);

// duration between successive polling
bpm.thirtysecondNote => dur pollDur;
// duration to pause when onset detected
bpm.quarterNote*2 => dur pauseDur;

// Array for keeping track of triggers for effects
int shredArray[20];
// store the start of the program
now => time startTime;

int gainCounter;
0 => gainCounter;
[ g.gain()*0.6, g.gain()*0.5, g.gain()*0.4, g.gain()*0.3 ] @=> float gainArray[];

// (BKO) This counter is used for the beat array
int beatCounter;
// (BKO) This beat array contains multiples of quarter notes
//       This is the part that varies the length of the drone sounds.
[ 1.0, 0.5, 0.125, 0.125, 0.5, 0.5, 1.0] @=> float beatArray[];

// This method stores the event triggers,
// the playHypnoDrone method will check the array
// to determine when to stop a shred.
fun void playShredForDuration(int shredID, dur playDuration)
{
    <<< me.id(), ": play for set duration">>>;
    playDuration * beatArray[beatCounter % beatArray.cap()] => now;
    beatCounter++;
    shredID +10 => shredArray.size;
    1 => shredArray[shredID-1];
}

/*
Can't remember where I found this code, but when I do,
I'll add a shout-out...
*/
fun void playHypnoDrone(float DroneBaseFrequency, float gain, dur fadeInIncrement, dur fadeOutDecrement)
{
 
    3.0 => float FilterMod; 
    12.0 => float SoundVariation; 
    .1 => float SweepingLFOFreq; 

    SinOsc lfo1 => blackhole; 
    SweepingLFOFreq => lfo1.freq; 

    Step freq => Phasor s1 => Gain s1_g; 
    3 => s1_g.op; 

    freq => s1_g; 
    freq => SinOsc s2 => NRev rev1 => LPF s2_f => PRCRev rev2 => Envelope e => Gain droneGain => dac; 
    s1_g => s2; 
    
    /* Start fade-in */
    500::ms => e.duration;
    gain => droneGain.gain;
    <<< "starting fadein...">>>;
    e.keyOn();
    
    <<< "setting drone gain to:", gain >>>;
    
    .8 => rev1.mix; 
    2 => s2_f.Q; 
    .05 => rev2.mix; 
    .1 => rev2.gain; 

    .2 => s2.gain; 

    int i; 
    
    while(droneGain.gain() > 0) 
    { 
        ((i * 5) % 8 * DroneBaseFrequency + DroneBaseFrequency => freq.next) * FilterMod => s2_f.freq; 
        100::ms => now; 
        i++; 
        Math.floor(lfo1.last() * SoundVariation) => s1_g.gain; 
        
        if(shredArray[me.id()-1] == 1)
        {
            <<< me.id(), ": starting fade out" >>>;
            
            e.keyOff();
            800::ms => now;
            0 => shredArray[me.id()-1];
            //droneGain =< dac;
            0 => droneGain.gain;
        }
    }
}

// infinite time loop
while( true )
{
    // print
    <<< "current envelope value:", p.last()*1000 >>>;
    // detect onset
    if( now > notBefore && p.last()*1000 > threshold*1.2 )
    {
        // do something
        <<< "BANG!!" >>>;
        spork ~ playHypnoDrone(Math.random2f(60, 120), gainArray[gainCounter % gainArray.cap()], 60::ms, 30::ms) @=> Shred shred1;
        spork ~ playShredForDuration(shred1.id(), bpm.quarterNote*4);
        gainCounter++;
        // compute time to resume checking
        now + pauseDur => notBefore;
    }
    
    // determines poll rate
    pollDur => now;
}
