import { View, StyleSheet, ViewStyle } from 'react-native';
import Svg, { Path, Circle, G } from 'react-native-svg';
import { getCurrentTheme } from '@/theme/store';

const theme = getCurrentTheme();

export  interface IconProps {
  size?: number;
  color?: string;
  style?: ViewStyle;
  strokeWidth?: number;
  filled?: boolean;
}

export const Heart: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
  filled = false,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 20C11.875 20 11.75 19.961 11.642 19.886C8.825 17.993 6.9 16.432 5.493 14.903C3.12 12.387 2.75 9.988 3.409 7.879C3.772 6.701 4.508 5.676 5.518 4.933C6.529 4.19 7.767 3.77 9.037 3.726C10.307 3.682 11.567 4.017 12.652 4.68C12.986 4.876 13.293 5.101 13.566 5.352L12 7L13.566 5.352C13.84 5.101 14.146 4.876 14.481 4.68C15.565 4.017 16.825 3.682 18.095 3.726C19.365 3.77 20.603 4.19 21.614 4.933C22.624 5.676 23.36 6.701 23.723 7.879C24.382 9.988 24.012 12.387 21.639 14.903C20.232 16.432 18.307 17.993 15.49 19.886C15.382 19.961 15.257 20 15.132 20H12Z"
        fill={filled ? color : 'none'}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const MessageCircle: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M21 11.5C21.0034 12.8199 20.6951 14.1219 20.1 15.3C19.3944 16.7118 18.3098 17.8992 16.9674 18.7293C15.6251 19.5594 14.0782 19.9994 12.5 20C11.1801 20.0035 9.87812 19.6951 8.7 19.1L3 21L4.9 15.3C4.30493 14.1219 3.99656 12.8199 4 11.5C4.00061 9.92179 4.44061 8.37488 5.27072 7.03258C6.10083 5.69028 7.28825 4.6056 8.7 3.90003C9.87812 3.30496 11.1801 2.99659 12.5 3.00003H13C15.0843 3.11502 17.053 3.99479 18.5291 5.47089C20.0052 6.94699 20.885 8.91568 21 11V11.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Share: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M18 8C19.6569 8 21 6.65685 21 5C21 3.34315 19.6569 2 18 2C16.3431 2 15 3.34315 15 5C15 6.65685 16.3431 8 18 8Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M6 15C7.65685 15 9 13.6569 9 12C9 10.3431 7.65685 9 6 9C4.34315 9 3 10.3431 3 12C3 13.6569 4.34315 15 6 15Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M18 22C19.6569 22 21 20.6569 21 19C21 17.3431 19.6569 16 18 16C16.3431 16 15 17.3431 15 19C15 20.6569 16.3431 22 18 22Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8.59 13.51L15.42 17.49"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M15.41 6.51L8.59 10.49"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const BookmarkSimple: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  filled = false,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M19 21L12 16L5 21V5C5 4.46957 5.21071 3.96086 5.58579 3.58579C5.96086 3.21071 6.46957 3 7 3H17C17.5304 3 18.0391 3.21071 18.4142 3.58579C18.7893 3.96086 19 4.46957 19 5V21Z"
        fill={filled ? color : 'none'}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ArrowLeft: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M19 12H5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 19L5 12L12 5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ArrowRight: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M5 12H19"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 5L19 12L12 19"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ChevronLeft: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M15 18L9 12L15 6"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Sparkle: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 3L13.9389 8.95492H20.0111L15.0361 12.5951L16.9749 18.55L12 14.9099L7.02513 18.55L8.96394 12.5951L3.98894 8.95492H10.0611L12 3Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Send: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M22 2L11 13"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M22 2L15 22L11 13L2 9L22 2Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Copy: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M20 9H11C9.89543 9 9 9.89543 9 11V20C9 21.1046 9.89543 22 11 22H20C21.1046 22 22 21.1046 22 20V11C22 9.89543 21.1046 9 20 9Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M5 15H4C3.46957 15 2.96086 14.7893 2.58579 14.4142C2.21071 14.0391 2 13.5304 2 13V4C2 3.46957 2.21071 2.96086 2.58579 2.58579C2.96086 2.21071 3.46957 2 4 2H13C13.5304 2 14.0391 2.21071 14.4142 2.58579C14.7893 2.96086 15 3.46957 15 4V5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ChevronRight: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M9 18L15 12L9 6"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Star: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
  filled = false,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"
        fill={filled ? color : 'none'}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const BookOpen: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M2 3H8C9.06087 3 10.0783 3.42143 10.8284 4.17157C11.5786 4.92172 12 5.93913 12 7V21C12 20.2044 11.6839 19.4413 11.1213 18.8787C10.5587 18.3161 9.79565 18 9 18H2V3Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M22 3H16C14.9391 3 13.9217 3.42143 13.1716 4.17157C12.4214 4.92172 12 5.93913 12 7V21C12 20.2044 12.3161 19.4413 12.8787 18.8787C13.4413 18.3161 14.2044 18 15 18H22V3Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Users: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M17 21V19C17 17.9391 16.5786 16.9217 15.8284 16.1716C15.0783 15.4214 14.0609 15 13 15H5C3.93913 15 2.92172 15.4214 2.17157 16.1716C1.42143 16.9217 1 17.9391 1 19V21"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9 11C11.2091 11 13 9.20914 13 7C13 4.79086 11.2091 3 9 3C6.79086 3 5 4.79086 5 7C5 9.20914 6.79086 11 9 11Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M23 21V19C22.9993 18.1137 22.7044 17.2528 22.1614 16.5523C21.6184 15.8519 20.8581 15.3516 20 15.13"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M16 3.13C16.8604 3.35031 17.623 3.85071 18.1676 4.55232C18.7122 5.25392 19.0078 6.11683 19.0078 7.005C19.0078 7.89318 18.7122 8.75608 18.1676 9.45769C17.623 10.1593 16.8604 10.6597 16 10.88"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const NotePencil: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 20H21"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M16.5 3.5C16.8978 3.10217 17.4374 2.87868 18 2.87868C18.2786 2.87868 18.5544 2.93355 18.8118 3.04015C19.0692 3.14676 19.303 3.30301 19.5 3.5C19.697 3.69698 19.8532 3.93083 19.9598 4.18821C20.0665 4.44559 20.1213 4.72144 20.1213 5C20.1213 5.27857 20.0665 5.55441 19.9598 5.81179C19.8532 6.06916 19.697 6.30302 19.5 6.5L7 19L3 20L4 16L16.5 3.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Settings: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 15C13.6569 15 15 13.6569 15 12C15 10.3431 13.6569 9 12 9C10.3431 9 9 10.3431 9 12C9 13.6569 10.3431 15 12 15Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M19.4 15C19.2669 15.3016 19.2272 15.6362 19.286 15.9606C19.3448 16.285 19.4995 16.5843 19.73 16.82L19.79 16.88C19.976 17.0657 20.1235 17.2863 20.2241 17.5291C20.3248 17.7719 20.3766 18.0322 20.3766 18.295C20.3766 18.5578 20.3248 18.8181 20.2241 19.0609C20.1235 19.3037 19.976 19.5243 19.79 19.71C19.6043 19.896 19.3837 20.0435 19.1409 20.1441C18.8981 20.2448 18.6378 20.2966 18.375 20.2966C18.1122 20.2966 17.8519 20.2448 17.6091 20.1441C17.3663 20.0435 17.1457 19.896 16.96 19.71L16.9 19.65C16.6643 19.4195 16.365 19.2648 16.0406 19.206C15.7162 19.1472 15.3816 19.1869 15.08 19.32C14.7842 19.4468 14.532 19.6572 14.3543 19.9255C14.1766 20.1938 14.0813 20.5082 14.08 20.83V21C14.08 21.5304 13.8693 22.0391 13.4942 22.4142C13.1191 22.7893 12.6104 23 12.08 23C11.5496 23 11.0409 22.7893 10.6658 22.4142C10.2907 22.0391 10.08 21.5304 10.08 21V20.91C10.0723 20.579 9.96512 20.258 9.77251 19.9887C9.5799 19.7194 9.31074 19.5143 9 19.4C8.69838 19.2669 8.36381 19.2272 8.03941 19.286C7.71502 19.3448 7.41568 19.4995 7.18 19.73L7.12 19.79C6.93425 19.976 6.71368 20.1235 6.47088 20.2241C6.22808 20.3248 5.96783 20.3766 5.705 20.3766C5.44217 20.3766 5.18192 20.3248 4.93912 20.2241C4.69632 20.1235 4.47575 19.976 4.29 19.79C4.10405 19.6043 3.95653 19.3837 3.85588 19.1409C3.75523 18.8981 3.70343 18.6378 3.70343 18.375C3.70343 18.1122 3.75523 17.8519 3.85588 17.6091C3.95653 17.3663 4.10405 17.1457 4.29 16.96L4.35 16.9C4.58054 16.6643 4.73519 16.365 4.794 16.0406C4.85282 15.7162 4.81312 15.3816 4.68 15.08C4.55324 14.7842 4.34276 14.532 4.07447 14.3543C3.80618 14.1766 3.49179 14.0813 3.17 14.08H3C2.46957 14.08 1.96086 13.8693 1.58579 13.4942C1.21071 13.1191 1 12.6104 1 12.08C1 11.5496 1.21071 11.0409 1.58579 10.6658C1.96086 10.2907 2.46957 10.08 3 10.08H3.09C3.42099 10.0723 3.742 9.96512 4.0113 9.77251C4.28059 9.5799 4.48572 9.31074 4.6 9C4.73312 8.69838 4.77282 8.36381 4.714 8.03941C4.65519 7.71502 4.50054 7.41568 4.27 7.18L4.21 7.12C4.02405 6.93425 3.87653 6.71368 3.77588 6.47088C3.67523 6.22808 3.62343 5.96783 3.62343 5.705C3.62343 5.44217 3.67523 5.18192 3.77588 4.93912C3.87653 4.69632 4.02405 4.47575 4.21 4.29C4.39575 4.10405 4.61632 3.95653 4.85912 3.85588C5.10192 3.75523 5.36217 3.70343 5.625 3.70343C5.88783 3.70343 6.14808 3.75523 6.39088 3.85588C6.63368 3.95653 6.85425 4.10405 7.04 4.29L7.1 4.35C7.33568 4.58054 7.63502 4.73519 7.95941 4.794C8.28381 4.85282 8.61838 4.81312 8.92 4.68H9C9.29577 4.55324 9.54802 4.34276 9.72569 4.07447C9.90337 3.80618 9.99872 3.49179 10 3.17V3C10 2.46957 10.2107 1.96086 10.5858 1.58579C10.9609 1.21071 11.4696 1 12 1C12.5304 1 13.0391 1.21071 13.4142 1.58579C13.7893 1.96086 14 2.46957 14 3V3.09C14.0013 3.41179 14.0966 3.72618 14.2743 3.99447C14.452 4.26276 14.7042 4.47324 15 4.6C15.3016 4.73312 15.6362 4.77282 15.9606 4.714C16.285 4.65519 16.5843 4.50054 16.82 4.27L16.88 4.21C17.0657 4.02405 17.2863 3.87653 17.5291 3.77588C17.7719 3.67523 18.0322 3.62343 18.295 3.62343C18.5578 3.62343 18.8181 3.67523 19.0609 3.77588C19.3037 3.87653 19.5243 4.02405 19.71 4.21C19.896 4.39575 20.0435 4.61632 20.1441 4.85912C20.2448 5.10192 20.2966 5.36217 20.2966 5.625C20.2966 5.88783 20.2448 6.14808 20.1441 6.39088C20.0435 6.63368 19.896 6.85425 19.71 7.04L19.65 7.1C19.4195 7.33568 19.2648 7.63502 19.206 7.95941C19.1472 8.28381 19.1869 8.61838 19.32 8.92V9C19.4468 9.29577 19.6572 9.54802 19.9255 9.72569C20.1938 9.90337 20.5082 9.99872 20.83 10H21C21.5304 10 22.0391 10.2107 22.4142 10.5858C22.7893 10.9609 23 11.4696 23 12C23 12.5304 22.7893 13.0391 22.4142 13.4142C22.0391 13.7893 21.5304 14 21 14H20.91C20.5882 14.0013 20.2738 14.0966 20.0055 14.2743C19.7372 14.452 19.5268 14.7042 19.4 15Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Bell: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M18 8C18 6.4087 17.3679 4.88258 16.2426 3.75736C15.1174 2.63214 13.5913 2 12 2C10.4087 2 8.88258 2.63214 7.75736 3.75736C6.63214 4.88258 6 6.4087 6 8C6 15 3 17 3 17H21C21 17 18 15 18 8Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M13.73 21C13.5542 21.3031 13.3019 21.5547 12.9982 21.7295C12.6946 21.9044 12.3504 21.9965 12 21.9965C11.6496 21.9965 11.3054 21.9044 11.0018 21.7295C10.6982 21.5547 10.4458 21.3031 10.27 21"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Search: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M21 21L16.65 16.65"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const MessageSquare: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M21 15C21 15.5304 20.7893 16.0391 20.4142 16.4142C20.0391 16.7893 19.5304 17 19 17H7L3 21V5C3 4.46957 3.21071 3.96086 3.58579 3.58579C3.96086 3.21071 4.46957 3 5 3H19C19.5304 3 20.0391 3.21071 20.4142 3.58579C20.7893 3.96086 21 4.46957 21 5V15Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Plus: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 5V19"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M5 12H19"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Pray: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 14C13.6569 14 15 12.6569 15 11C15 9.34315 13.6569 8 12 8C10.3431 8 9 9.34315 9 11C9 12.6569 10.3431 14 12 14Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 4C13.0609 4 14.0783 4.42143 14.8284 5.17157C15.5786 5.92172 16 6.93913 16 8"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 14V20"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8 18H16"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Dove: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 21C11.5 21 11.1 20.75 10.8 20.3C8.5 16.8 6.9 14.1 6 12.2C5.1 10.3 4.5 8.5 4.2 6.8C4.1 6.3 4 5.7 4 5C4 4.2 4.2 3.5 4.7 2.9C5.2 2.3 5.8 2 6.5 2H8.5C9.2 2 9.8 2.3 10.3 2.9C10.8 3.5 11 4.2 11 5V8.4L12.3 7.1C12.7 6.7 13.2 6.5 13.8 6.5C14.4 6.5 14.9 6.7 15.3 7.1L16.9 8.7C17.3 9.1 17.5 9.6 17.5 10.2C17.5 10.8 17.3 11.3 16.9 11.7L15.6 13H19C19.8 13 20.5 13.2 21.1 13.7C21.7 14.2 22 14.8 22 15.5V17.5C22 18.2 21.7 18.8 21.1 19.3C20.5 19.8 19.8 20 19 20H12.5C12.2 20.7 11.7 21 11 21H12Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M14 10C14.5523 10 15 9.55228 15 9C15 8.44772 14.5523 8 14 8C13.4477 8 13 8.44772 13 9C13 9.55228 13.4477 10 14 10Z"
        fill={color}
      />
    </Svg>
  </View>
);

export const OliveBranch: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 3C7.5 3 4 5.5 4 9C4 11.5 6 13.5 9 14.5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 3C16.5 3 20 5.5 20 9C20 11.5 18 13.5 15 14.5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 3V21"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8 9C8 9 9.5 10 12 10C14.5 10 16 9 16 9"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8 13C8 13 9.5 14 12 14C14.5 14 16 13 16 13"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8 17C8 17 9.5 18 12 18C14.5 18 16 17 16 17"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Bible: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M4 19V5C4 3.89543 4.89543 3 6 3H19C19.5523 3 20 3.44772 20 4V18C20 18.5523 19.5523 19 19 19H4Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M4 19C4 20.1046 4.89543 21 6 21H19C19.5523 21 20 20.5523 20 20V19"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 7V17"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8 12H16"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ScrollIcon: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M17 3H7C5.89543 3 5 3.89543 5 5V19C5 20.1046 5.89543 21 7 21H17C18.1046 21 19 20.1046 19 19V5C19 3.89543 18.1046 3 17 3Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M19 6C19 6 15 8 12 8C9 8 5 6 5 6"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 8V20"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ChevronUp: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M6 15L12 9L18 15"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ChevronDown: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M6 9L12 15L18 9"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Brain: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 4.5C10.6193 4.5 9.5 5.61929 9.5 7C9.5 8.38071 10.6193 9.5 12 9.5C13.3807 9.5 14.5 8.38071 14.5 7C14.5 5.61929 13.3807 4.5 12 4.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M15.5 13C15.5 11.067 13.933 9.5 12 9.5C10.067 9.5 8.5 11.067 8.5 13"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M19.5 7C19.5 3.96243 16.0376 1.5 12 1.5C7.96243 1.5 4.5 3.96243 4.5 7C4.5 8.77934 5.21005 10.3977 6.375 11.625C6.375 11.625 6.5 11.75 6.5 12C6.5 12.3978 6.34196 12.7794 6.06066 13.0607C5.77936 13.342 5.39782 13.5 5 13.5H3.5C3.10218 13.5 2.72064 13.658 2.43934 13.9393C2.15804 14.2206 2 14.6022 2 15V16C2 16.3978 2.15804 16.7794 2.43934 17.0607C2.72064 17.342 3.10218 17.5 3.5 17.5H4.5C5.05228 17.5 5.5 17.9477 5.5 18.5V21C5.5 21.3978 5.65804 21.7794 5.93934 22.0607C6.22064 22.342 6.60218 22.5 7 22.5H17C17.3978 22.5 17.7794 22.342 18.0607 22.0607C18.342 21.7794 18.5 21.3978 18.5 21V18.5C18.5 17.9477 18.9477 17.5 19.5 17.5H20.5C20.8978 17.5 21.2794 17.342 21.5607 17.0607C21.842 16.7794 22 16.3978 22 16V15C22 14.6022 21.842 14.2206 21.5607 13.9393C21.2794 13.658 20.8978 13.5 20.5 13.5H19C18.6022 13.5 18.2206 13.342 17.9393 13.0607C17.658 12.7794 17.5 12.3978 17.5 12C17.5 11.75 17.625 11.625 17.625 11.625C18.7899 10.3977 19.5 8.77934 19.5 7Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const PrayingHands: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 2V6.5M12 6.5V12.5C12 13.88 13.12 15 14.5 15C15.88 15 17 13.88 17 12.5V7C17 5.62 15.88 4.5 14.5 4.5C13.12 4.5 12 5.62 12 6.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 6.5V12.5C12 13.88 10.88 15 9.5 15C8.12 15 7 13.88 7 12.5V7C7 5.62 8.12 4.5 9.5 4.5C10.88 4.5 12 5.62 12 6.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M7 12.5V16.5C7 17.8807 8.11929 19 9.5 19C10.8807 19 12 17.8807 12 16.5V12.5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M17 12.5V16.5C17 17.8807 15.8807 19 14.5 19C13.1193 19 12 17.8807 12 16.5V12.5"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9.5 19C9.5 19 9 21.5 10.5 22H13.5C15 21.5 14.5 19 14.5 19"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Crown: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M2.5 8L5 17H19L21.5 8L16.5 11L12 5L7.5 11L2.5 8Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M5 17H19V19C19 19.5523 18.5523 20 18 20H6C5.44772 20 5 19.5523 5 19V17Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

// export const Bible: React.FC<IconProps> = ({ 
//   size = 24, 
//   color = theme.colors.text.secondary,
//   strokeWidth = 1.5,
//   style,
// }) => (
//   <View style={style}>
//     <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
//       <Path
//         d="M12 2V7.5M12 7.5V20M12 7.5L6.5 4M12 7.5L17.5 4M3 17.2V6C3 4.89543 3.89543 4 5 4H19C20.1046 4 21 4.89543 21 6V17.2C21 18.8802 19.6569 20.2 18 20.2H6C4.34315 20.2 3 18.8802 3 17.2Z"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//     </Svg>
//   </View>
// );

// export const Dove: React.FC<IconProps> = ({ 
//   size = 24, 
//   color = theme.colors.text.secondary,
//   strokeWidth = 1.5,
//   style,
// }) => (
//   <View style={style}>
//     <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
//       <Path
//         d="M20.5 7.5C20.5 9.433 18.933 11 17 11C15.067 11 13.5 9.433 13.5 7.5C13.5 5.567 15.067 4 17 4C18.933 4 20.5 5.567 20.5 7.5Z"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//       <Path
//         d="M17 11V20"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//       <Path
//         d="M17 16L3.5 13.5L6 7L12.5 8.5"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//     </Svg>
//   </View>
// );

export const Cross: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 4V20M7 9V15H17V9H7Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Peace: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 2V22M12 12L19.0711 4.92893M12 12L4.92893 19.0711M12 12L4.92893 4.92893M12 12L19.0711 19.0711"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Halo: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 16C14.2091 16 16 14.2091 16 12C16 9.79086 14.2091 8 12 8C9.79086 8 8 9.79086 8 12C8 14.2091 9.79086 16 12 16Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 4C16.4183 4 20 7.58172 20 12C20 16.4183 16.4183 20 12 20C7.58172 20 4 16.4183 4 12C4 7.58172 7.58172 4 12 4Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 2C17.5228 2 22 6.47715 22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Church: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 3V7M12 7V10M12 7L16 5M12 7L8 5M5 21V11L2 9L12 3L22 9L19 11V21H5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9 21V15H15V21"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Wheat: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 10V20M8.5 8.5C8.5 6.5 10 5 12 5C14 5 15.5 6.5 15.5 8.5C15.5 10.5 14 12 12 12C10 12 8.5 10.5 8.5 8.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M8.5 15.5C8.5 13.5 10 12 12 12C14 12 15.5 13.5 15.5 15.5C15.5 17.5 14 19 12 19C10 19 8.5 17.5 8.5 15.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Fish: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M19.1129 12.5C18.9388 15.0355 16.8139 17 14.2097 17C11.6056 17 9.48065 15.0355 9.30645 12.5C9.48065 9.96447 11.6056 8 14.2097 8C16.8139 8 18.9388 9.96447 19.1129 12.5Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9.30645 12.5H3M19.1129 12.5H21"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M14.2097 10V11"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

// export const OliveBranch: React.FC<IconProps> = ({ 
//   size = 24, 
//   color = theme.colors.text.secondary,
//   strokeWidth = 1.5,
//   style,
// }) => (
//   <View style={style}>
//     <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
//       <Path
//         d="M12 4C7.5 4 4 6.5 4 10C4 12.5 6 14.5 9 15.5"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//       <Path
//         d="M12 4C16.5 4 20 6.5 20 10C20 12.5 18 14.5 15 15.5"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//       <Path
//         d="M12 4V20"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//       <Path
//         d="M8 10C8 10 9.5 11 12 11C14.5 11 16 10 16 10"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//       <Path
//         d="M8 14C8 14 9.5 15 12 15C14.5 15 16 14 16 14"
//         stroke={color}
//         strokeWidth={strokeWidth}
//         strokeLinecap="round"
//         strokeLinejoin="round"
//       />
//     </Svg>
//   </View>
// );

export const X: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  style,
  strokeWidth = 1.5,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M6 18L18 6M6 6l12 12"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Scroll: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M17 3H7C5.89543 3 5 3.89543 5 5V19C5 20.1046 5.89543 21 7 21H17C18.1046 21 19 20.1046 19 19V5C19 3.89543 18.1046 3 17 3Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M19 6C19 6 15 8 12 8C9 8 5 6 5 6"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M12 8V20"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ScrollText: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M19 3H7C5.89543 3 5 3.89543 5 5V16.1707C5 16.7571 5.23422 17.3214 5.65147 17.7386L8.91274 21H17C18.1046 21 19 20.1046 19 19V5C19 3.89543 18.1046 3 17 3Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9 8H15"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9 12H15"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M9 16H13"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const Book: React.FC<IconProps> = ({ 
  size = 24, 
  color = theme.colors.text.secondary,
  strokeWidth = 1.5,
  style,
}) => (
  <View style={style}>
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M4 19.5C4 18.837 4.26339 18.2011 4.73223 17.7322C5.20107 17.2634 5.83696 17 6.5 17H20"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Path
        d="M6.5 2H20V22H6.5C5.83696 22 5.20107 21.7366 4.73223 21.2678C4.26339 20.7989 4 20.163 4 19.5V4.5C4 3.83696 4.26339 3.20107 4.73223 2.73223C5.20107 2.26339 5.83696 2 6.5 2Z"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  </View>
);

export const ReligiousIconMap = {
  dove: Dove,
  oliveBranch: OliveBranch,
  bible: Bible,
  scroll: ScrollIcon,
  scrollText: ScrollText,
  church: Church,
  prayingHands: PrayingHands,
  cross: Cross,
};

export type ReligiousIconName = keyof typeof ReligiousIconMap;

// Helper function to render icons dynamically
export const renderReligiousIcon = (name: ReligiousIconName, props: IconProps) => {
  const Icon = ReligiousIconMap[name];
  return Icon ? <Icon {...props} /> : null;
};

// Export a map of all icons for dynamic usage
export const IconMap = {
  heart: Heart,
  messageCircle: MessageCircle,
  share: Share,
  bookmarkSimple: BookmarkSimple,
  arrowLeft: ArrowLeft,
  arrowRight: ArrowRight,
  sparkle: Sparkle,
  send: Send,
  copy: Copy,
  chevronRight: ChevronRight,
  star: Star,
  bookOpen: BookOpen,
  users: Users,
  notePencil: NotePencil,
  settings: Settings,
  bell: Bell,
  search: Search,
  messageSquare: MessageSquare,
  plus: Plus,
  pray: Pray,
  x: X,
  religious: ReligiousIconMap,
  chevronUp: ChevronUp,
  chevronDown: ChevronDown,
  brain: Brain,
  prayingHands: PrayingHands,
  crown: Crown,
  cross: Cross,
  peace: Peace,
  dove: Dove,
  oliveBranch: OliveBranch,
  bible: Bible,
  scroll: Scroll,
  scrollText: ScrollText,
  book: Book,
  wheat: Wheat,
  fish: Fish,
  church: Church,
};

// Export types for TypeScript support
export type IconName = keyof typeof IconMap;

export interface IconProps {
  size?: number;
  color?: string;
  style?: ViewStyle;
  filled?: boolean;
}

export default IconMap;