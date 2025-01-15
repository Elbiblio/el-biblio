// types/svg.ts
export interface SvgElementAttributes {
    id?: string;
    fill?: string;
    stroke?: string;
    strokeWidth?: number | string;
    style?: string | Record<string, string | number>;
    transform?: string;
    className?: string;
    width?: number | string;
    height?: number | string;
    x?: number | string;
    y?: number | string;
    cx?: number | string;
    cy?: number | string;
    r?: number | string;
    rx?: number | string;
    ry?: number | string;
    d?: string;
    points?: string;
    viewBox?: string;
    preserveAspectRatio?: string;
    [key: string]: any;
  }
  
  export interface ParsedSvgElement {
    type: string;
    attributes: SvgElementAttributes;
    children: ParsedSvgElement[];
  }
  
  export interface StyleDefinition {
    selector: string;
    properties: Record<string, string>;
  }
  
  export interface ParsedDef {
    type: 'style' | 'gradient' | 'pattern' | 'mask' | 'clipPath';
    id?: string;
    content: string;
    elements?: ParsedSvgElement[];
  }
  
  export interface ParsedSvg {
    viewBox: string;
    width: string;
    height: string;
    elements: ParsedSvgElement[];
    defs: ParsedDef[];
  }
  
  export interface Transform {
    translateX?: number;
    translateY?: number;
    scale?: number;
    rotate?: string;
    skewX?: string;
    skewY?: string;
  }
  
  export interface ColorOverrides {
    [key: string]: string;
  }
  
  export interface SvgUriProps {
    uri: string;
    width?: number | string;
    height?: number | string;
    fill?: string;
    stroke?: string;
    scale?: number;
    onError?: (error: Error) => void;
    onLoad?: () => void;
    style?: Record<string, any>;
    preserveAspectRatio?: string;
    color?: string;
    colorOverrides?: ColorOverrides;
    fallbackElement?: React.ReactNode;
  }
  