// packages
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