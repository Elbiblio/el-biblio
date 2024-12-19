// packages
import { Brain, Cross, Heart, HomeLight, IconProps, Scroll } from '@/components/Icons';
import { Dimensions, PixelRatio, Platform } from 'react-native';

// Retrieve initial screen's width
let screenWidth = Dimensions.get('window').width;

// Retrieve initial screen's height
let screenHeight = Dimensions.get('window').height;

export const isiPAD = screenHeight / screenWidth < 1.6;
export const isTablet = screenHeight / screenWidth < 1.6;

export const isIOS = Platform.OS === 'ios';
export const isAndroid = Platform.OS === 'android';
export const isX = isIphoneXorAbove();

export function isIphoneXorAbove() {
	const dimen = Dimensions.get('window');
	return (
		Platform.OS === 'ios' &&
		!Platform.isPad &&
		!Platform.isTV &&
		(dimen.height === 812 ||
			dimen.width === 812 ||
			dimen.height === 896 ||
			dimen.height === 667 ||
			dimen.width === 375 ||
			dimen.width === 414 ||
			dimen.width === 896 ||
			dimen.width === 390 ||
			dimen.height === 844 ||
			dimen.height === 926 ||
			dimen.width === 428 ||
			dimen.height === 852 ||
			dimen.width === 393 ||
			dimen.height === 932 ||
			dimen.width === 932)
	);
}

/**
 * Converts provided width percentage to independent pixel (dp).
 * @param  {string} widthPercent The percentage of screen's width that UI element should cover
 *                               along with the percentage symbol (%).
 * @return {number}              The calculated dp depending on current device's screen width.
 */
const wp = (widthPercent : string | number) => {
	// Parse string percentage input and convert it to number.
	const elemWidth =
		typeof widthPercent === 'number' ? widthPercent : parseFloat(widthPercent);

	// Use PixelRatio.roundToNearestPixel method in order to round the layout
	// size (dp) to the nearest one that correspons to an integer number of pixels.
	return PixelRatio.roundToNearestPixel((screenWidth * elemWidth) / 100);
};

/**
 * Converts provided height percentage to independent pixel (dp).
 * @param  {string} heightPercent The percentage of screen's height that UI element should cover
 *                                along with the percentage symbol (%).
 * @return {number}               The calculated dp depending on current device's screen height.
 */
const hp = (heightPercent : string | number) => {
	// Parse string percentage input and convert it to number.
	const elemHeight =
		typeof heightPercent === 'number'
			? heightPercent
			: parseFloat(heightPercent);

	// Use PixelRatio.roundToNearestPixel method in order to round the layout
	// size (dp) to the nearest one that correspons to an integer number of pixels.
	return PixelRatio.roundToNearestPixel((screenHeight * elemHeight) / 100);
};

/**
 * Event listener function that detects orientation change (every time it occurs) and triggers
 * screen rerendering. It does that, by changing the state of the screen where the function is
 * called. State changing occurs for a new state variable with the name 'orientation' that will
 * always hold the current value of the orientation after the 1st orientation change.
 * Invoke it inside the screen's constructor or in componentDidMount lifecycle method.
 * @param {object} that Screen's class component this variable. The function needs it to
 *                      invoke setState method and trigger screen rerender (this.setState()).
 */
const listenOrientationChange = (that : any) => {
	Dimensions.addEventListener('change', (newDimensions) => {
		// Retrieve and save new dimensions
		screenWidth = newDimensions.window.width;
		screenHeight = newDimensions.window.height;

		// Trigger screen's rerender with a state update of the orientation variable
		that.setState({
			orientation: screenWidth < screenHeight ? 'portrait' : 'landscape',
		});
	});
};

export { hp, listenOrientationChange, wp };

export const SCREEN_DIMENSIONS = {
  height: screenHeight,
  width: screenWidth,
};

export const ANIMATIONS = {
  SPRING_CONFIG: {
    damping: 15,
    mass: 1,
    stiffness: 90,
  },
  TIMING_CONFIG: {
    duration: 300,
  }
} as const;

export interface OnboardingStep {
  id: string;
  title: string;
  subtitle: string;
  description: string;
  practices: string[];
  Icon: React.FC<IconProps>;
  color: string;
}

export const STEPS: OnboardingStep[] = [
  {
    id: 'welcome',
    title: 'Welcome to El-Biblio',
    subtitle: 'Your Spiritual Growth Companion',
    description: 'Engage in El-Biblio daily verse selections based on four foundational virtues of knowledge, humility, faith and love.',
    practices: ['Vote on daily verse selections', 'Study and Share your reflections', 'Join a Word Hub or start one for deeper reflections'],
    Icon: Scroll,
    color: '#8B5E3C', // Wooden theme primary
  },
  {
    id: 'knowledge',
    title: 'Knowledge',
    subtitle: 'The Foundation',
    description: 'Understanding God and His purpose gives us the wisdom to begin our spiritual journey. When combined with other virtues, it helps us make wise choices, understand others, and grow in discernment.',
    practices: [
      'Read scripture with intention, not just for information',
      'Write down at least one insight a week',
      'Share what you learn with at least one person per week'
    ],
    Icon: Brain,
    color: '#4A6FA5', // Ocean theme primary
  },
  {
    id: 'humility',
    title: 'Humility',
    subtitle: 'The Soil',
    description: 'Once we gain knowledge, humility prepares our hearts to grow. It allows us to set aside our ego, learn from others, and create space for honesty, justice and transformation. Combined with other virtues, it enables patience, gentleness, and self-control.',
    practices: [
      'Listen twice as much as you speak',
      'Acknowledge at least one mistake per week and learn from it',
      'Serve someone without seeking recognition'
    ],
    Icon: Cross,
    color: '#638B6C', // Sage theme primary
  },
  {
    id: 'faith',
    title: 'Faith',
    subtitle: 'The Strength',
    description: 'Built on knowledge and humility, faith gives us courage and zeal to trust and follow in God\'s ways. It provides the strength to persist in difficulties and the passion and hope to await divine justice and perfection. When combined with other virtues, it produces perseverance, peace, and fortitude.',
    practices: [
      'Say more thanksgiving and virtue seeking prayers than material needs',
      'Take a leap of faith in helping/blessing someone per week',
      'Record/share your testimony of God\'s faithfulness weekly'
    ],
    Icon: HomeLight,
    color: '#C85F4B', // Like color
  },
  {
    id: 'love',
    title: 'Love',
    subtitle: 'The Fullness',
    description: 'Supported by knowledge, humility, and faith, love brings all virtues to their fullness. It transforms our relationships with God and others. Combined with other virtues, it produces joy, kindness, and goodness.',
    practices: [
      'Identify at least one person in need around you a week',
      'Put their needs before your own comfort',
      'Show compassion and/or share your resources with them'
    ],
    Icon: Heart,
    color: '#B66B68', // Error color
  }
];

