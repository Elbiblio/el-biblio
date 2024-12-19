import { View, StyleSheet, ViewStyle } from 'react-native';
import Svg, { Path, Circle, G } from 'react-native-svg';
import AntDesign from 'react-native-vector-icons/AntDesign';
import Feather from 'react-native-vector-icons/Feather';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';
import FontAwesome6 from 'react-native-vector-icons/FontAwesome6';
import Entypo from 'react-native-vector-icons/Entypo';
import { getCurrentTheme } from '@/theme/store';

const theme = getCurrentTheme();

export interface IconProps {
  size?: number;
  color?: string;
  style?: ViewStyle;
  strokeWidth?: number;
  filled?: boolean;
}

// Standard icons using vector-icons
export const Heart = ({ size = 24, color = theme.colors.text.secondary, style, filled }: IconProps) => (
  <View style={style}>
    <AntDesign name={filled ? "heart" : "hearto"} size={size} color={color} />
  </View>
);

export const Give = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="hand-coin-outline" size={size} color={color} />
  </View>
);

export const MessageCircle = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="message-circle" size={size} color={color} />
  </View>
);

export const Share = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="share-2" size={size} color={color} />
  </View>
);

export const BookmarkSimple = ({ size = 24, color = theme.colors.text.secondary, style, filled }: IconProps) => (
  <View style={style}>
    <Feather name={filled ? "bookmark" : "bookmark"} size={size} color={color} />
  </View>
);

export const ArrowLeft = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="arrow-left" size={size} color={color} />
  </View>
);

export const ArrowRight = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="arrow-right" size={size} color={color} />
  </View>
);

export const ArrowRightBold = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="arrow-right-bold-outline" size={size} color={color} />
  </View>
);

export const ArrowRightPlay = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="arrow-right-drop-circle-outline" size={size} color={color} />
  </View>
);

export const Clock = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="clock-outline" size={size} color={color} />
  </View>
);

export const Sparkle = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <AntDesign name="star" size={size} color={color} />
  </View>
);

export const Send = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="send" size={size} color={color} />
  </View>
);

export const Copy = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="copy" size={size} color={color} />
  </View>
);

export const Info = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="information-variant" size={size} color={color} />
  </View>
);

export const InfoPro = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Entypo name="info" size={size} color={color} />
  </View>
);

export const InfoCircle = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Entypo name="info-with-circle" size={size} color={color} />
  </View>
);

export const Help = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="help-circle" size={size} color={color} />
  </View>
);

export const ChevronLeft = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="chevron-left" size={size} color={color} />
  </View>
);

export const BulbTwo = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="lightbulb-multiple" size={size} color={color} />
  </View>
);

export const BulbDiverse = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="lightbulb-multiple-outline" size={size} color={color} />
  </View>
);

export const BulbGroup = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="lightbulb-group-outline" size={size} color={color} />
  </View>
);

export const Brain = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="brain" size={size} color={color} />
  </View>
);

export const ChevronRight = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="chevron-right" size={size} color={color} />
  </View>
);

export const Star = ({ size = 24, color = theme.colors.text.secondary, style, filled }: IconProps) => (
  <View style={style}>
    <AntDesign name={filled ? "star" : "staro"} size={size} color={color} />
  </View>
);

export const Lock = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="lock" size={size} color={color} />
  </View>
);

export const Book = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <FontAwesome6 name="book" size={size} color={color} />
  </View>
);

export const BookReader = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <FontAwesome6 name="book-open-reader" size={size} color={color} />
  </View>
);

export const BookKnowledge = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="book-open-page-variant-outline" size={size} color={color} />
  </View>
);

export const ViewGrid = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="view-grid-outline" size={size} color={color} />
  </View>
);

export const ViewList = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="view-list-outline" size={size} color={color} />
  </View>
);

export const Bold = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="format-bold" size={size} color={color} />
  </View>
);

export const Italic = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="format-italic" size={size} color={color} />
  </View>
);

export const Underline = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="format-underline" size={size} color={color} />
  </View>
);

export const List = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="format-list-bulleted" size={size} color={color} />
  </View>
);

export const ListOrdered = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="format-list-numbered" size={size} color={color} />
  </View>
);

export const Cross = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="cross-outline" size={size} color={color} />
  </View>
);

export const Quote = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Entypo name="quote" size={size} color={color} />
  </View>
);

export const HelpCircle = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="help-circle" size={size} color={color} />
  </View>
);

export const Filter = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="filter" size={size} color={color} />
  </View>
);

export const BookOpen = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <FontAwesome6 name="book-open" size={size} color={color} />
  </View>
);

export const BookOpenFeather = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="book-open" size={size} color={color} />
  </View>
);

export const Users = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="users" size={size} color={color} />
  </View>
);

export const PencilLock = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="pencil-lock-outline" size={size} color={color} />
  </View>
);

export const NotePencil = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="edit" size={size} color={color} />
  </View>
);

export const Settings = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="settings" size={size} color={color} />
  </View>
);

export const Bell = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="bell" size={size} color={color} />
  </View>
);

export const Search = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="search" size={size} color={color} />
  </View>
);

export const Plus = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="plus" size={size} color={color} />
  </View>
);

export const X = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="x" size={size} color={color} />
  </View>
);

export const ChevronUp = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="chevron-up" size={size} color={color} />
  </View>
);

export const ChevronDown = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="chevron-down" size={size} color={color} />
  </View>
);

export const Crown = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="crown" size={size} color={color} />
  </View>
);

export const Check = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="check-circle-outline" size={size} color={color} />
  </View>
);

export const Upvote: React.FC<IconProps> = ({ 
  size = 24, 
  color = "currentColor",
  style,
  strokeWidth = 1.5,
  filled = false,
}) => {
  const adjustedStrokeWidth = (strokeWidth * size) / 24;
  
  return (
    <View style={style}>
      <Svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
      >
        <G>
          {/* Main arrow shape */}
          <Path
            d="M12 20.5v-14m0 0l-6 6m6-6l6 6"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          {/* Base line for grounding */}
          <Path
            d="M6.5 20.5h11"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
          />
          {/* Optional fill for arrow head when filled */}
          {filled && (
            <Path
              d="M12 7.5l4.5 4.5h-9l4.5-4.5z"
              fill={color}
              stroke="none"
            />
          )}
        </G>
      </Svg>
    </View>
  );
};

export const MessageSquare = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <Feather name="message-square" size={size} color={color} />
  </View>
);

export const Synagogue = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <FontAwesome6 name="synagogue" size={size} color={color} />
  </View>
);

export const HomeLight = ({ size = 24, color = theme.colors.text.secondary, style }: IconProps) => (
  <View style={style}>
    <MaterialCommunityIcons name="home-lightbulb-outline" size={size} color={color} />
  </View>
);

export const DivineLight: React.FC<IconProps> = ({ 
  size = 24, 
  color = "currentColor",
  style,
  strokeWidth = 1.5
}) => {
  const adjustedStrokeWidth = (strokeWidth * size) / 24;
  
  return (
    <View style={style}>
      <Svg width={size} height={size} viewBox="0 0 24 24">
        <G>
          {/* Divine Light from Above */}
          
          {/* Lamp/Vessel of the Soul */}
          <Path
            d="M7 14c0-2.8 2.2-5 5-5s5 2.2 5 5c0 1.6-0.8 3.1-2 4h-6c-1.2-0.9-2-2.4-2-4z"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            fill="none"
          />
          
          {/* Light Emanating from Lamp */}
          <Path
            d="M10 18h4M11 21h2"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
          />
          
          {/* Flame/Inner Light */}
          <Path
            d="M12 11c1.1 0 2 0.9 2 2 0 1.1-0.9 2-2 2s-2-0.9-2-2c0-1.1 0.9-2 2-2z"
            fill={color}
          />
          
          {/* Subtle Radiance */}
          <Path
            d="M12 7c0.5-0.5 1.5-0.5 2 0M10 7c0.5-0.5 1.5-0.5 2 0"
            stroke={color}
            strokeWidth={adjustedStrokeWidth * 0.75}
            strokeLinecap="round"
            opacity="0.6"
          />
        </G>
      </Svg>
    </View>
  );
};

export const DivineStrength: React.FC<IconProps> = ({ 
  size = 24, 
  color = "currentColor",
  style,
  strokeWidth = 1.5
}) => {
  const adjustedStrokeWidth = (strokeWidth * size) / 24;
  
  return (
    <View style={style}>
      <Svg width={size} height={size} viewBox="0 0 24 24">
        <G>
          {/* Central Pillar of Light */}
          <Path
            d="M12 3v18"
            stroke={color}
            strokeWidth={adjustedStrokeWidth * 1.5}
            strokeLinecap="round"
          />
          {/* Radiating Light */}
          <Path
            d="M12 3l4 4M12 3l-4 4"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
          />
          {/* Shield of Faith */}
          <Path
            d="M12 21c-4 0-7-3-7-7V8l7-4 7 4v6c0 4-3 7-7 7z"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          {/* Crown/Halo */}
          <Path
            d="M8.5 3.5C10 2 12 2 12 2s2 0 3.5 1.5"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
          />
          {/* Inner Strength Symbol */}
          <Circle
            cx={12}
            cy={12}
            r={2}
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            fill="none"
          />
        </G>
      </Svg>
    </View>
  );
};

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


export const PrayingHands: React.FC<IconProps> = ({ 
  size = 24, 
  color = "currentColor",
  style,
  strokeWidth = 1.5,
}) => {
  // Scale stroke width based on size for consistent look
  const adjustedStrokeWidth = (strokeWidth * size) / 24;
  
  return (
    <View style={style}>
      <Svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
      >
        <G>
          {/* Center line */}
          <Path
            d="M12 2.25v4"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          
          {/* Right hand upper part - refined curve */}
          <Path
            d="M12 6.25v6.25c0 1.38 1.12 2.5 2.5 2.5 1.38 0 2.5-1.12 2.5-2.5v-5.5c0-1.38-1.12-2.5-2.5-2.5-1.38 0-2.5 1.12-2.5 2.5"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          
          {/* Left hand upper part - refined curve */}
          <Path
            d="M12 6.25v6.25c0 1.38-1.12 2.5-2.5 2.5-1.38 0-2.5-1.12-2.5-2.5v-5.5c0-1.38 1.12-2.5 2.5-2.5 1.38 0 2.5 1.12 2.5 2.5"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          
          {/* Left hand lower part - smoother transition */}
          <Path
            d="M7 12.5v4c0 1.38 1.12 2.5 2.5 2.5 1.38 0 2.5-1.12 2.5-2.5v-4"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          
          {/* Right hand lower part - smoother transition */}
          <Path
            d="M17 12.5v4c0 1.38-1.12 2.5-2.5 2.5-1.38 0-2.5-1.12-2.5-2.5v-4"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          
          {/* Base curve - refined shape */}
          <Path
            d="M9.5 19c0 0-0.5 2.25 1 2.75h3c1.5-0.5 1-2.75 1-2.75"
            stroke={color}
            strokeWidth={adjustedStrokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </G>
      </Svg>
    </View>
  );
};

// Icon Maps
export const ReligiousIconMap = {
  divineStrength: DivineStrength,
  prayingHands: PrayingHands,
  dove: Dove,
  oliveBranch: OliveBranch,
  bible: Bible,
  scroll: Scroll,
  church: Church,
  cross: Cross,
  wheat: Wheat,
  fish: Fish,
};

export type ReligiousIconName = keyof typeof ReligiousIconMap;

export const IconMap = {
  heart: Heart,
  messageCircle: MessageCircle,
  share: Share,
  book: Book,
  bookKnowledge: BookKnowledge,
  bookOpen: BookOpen,
  bookReader: BookReader,
  bookmarkSimple: BookmarkSimple,
  arrowLeft: ArrowLeft,
  arrowRight: ArrowRight,
  sparkle: Sparkle,
  send: Send,
  copy: Copy,
  info: Info,
  help: Help,
  give: Give,
  chevronLeft: ChevronLeft,
  chevronRight: ChevronRight,
  chevronUp: ChevronUp,
  chevronDown: ChevronDown,
  star: Star,
  users: Users,
  notePencil: NotePencil,
  settings: Settings,
  bell: Bell,
  search: Search,
  plus: Plus,
  x: X,
  ...ReligiousIconMap,
};

export type IconName = keyof typeof IconMap;

export default IconMap;