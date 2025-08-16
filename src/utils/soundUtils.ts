import { Howl } from 'howler';

// Sound URLs
const SOUND_URLS = {
  starClick: 'https://assets.codepen.io/21542/click-2.mp3',
  starLight: 'https://assets.codepen.io/21542/pop-up-on.mp3',
  starReveal: 'https://assets.codepen.io/21542/pop-down.mp3',
  ambient: 'https://assets.codepen.io/21542/ambient-loop.mp3',
};

// Preload sounds
const sounds: Record<string, Howl> = {};

Object.entries(SOUND_URLS).forEach(([key, url]) => {
  sounds[key] = new Howl({
    src: [url],
    volume: key === 'ambient' ? 0.2 : 0.5,
    loop: key === 'ambient',
  });
});

// Sound utility functions
export function playSound(
  soundName: 'starClick' | 'starLight' | 'starReveal' | 'ambient' | 'uiClick',
  options: { volume?: number; loop?: boolean } = {}
) {
  // For uiClick, default to starClick if not available
  const actualSoundName = soundName === 'uiClick' ? 'starClick' : soundName;
  
  if (sounds[actualSoundName]) {
    // Set volume if provided
    if (options.volume !== undefined) {
      sounds[actualSoundName].volume(options.volume);
    }
    
    // Set loop if provided
    if (options.loop !== undefined) {
      sounds[actualSoundName].loop(options.loop);
    }
    
    // Play the sound
    sounds[actualSoundName].play();
    
    console.log(`🔊 Playing sound: ${soundName}`);
  } else {
    console.warn(`⚠️ Sound not found: ${soundName}`);
  }
}

export const stopSound = (soundName: keyof typeof SOUND_URLS) => {
  if (sounds[soundName]) {
    sounds[soundName].stop();
  }
};

export const startAmbientSound = () => {
  if (!sounds.ambient.playing()) {
    sounds.ambient.play();
  }
};

export const stopAmbientSound = () => {
  sounds.ambient.stop();
};