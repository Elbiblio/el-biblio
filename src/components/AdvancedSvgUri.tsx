// AdvancedSvgUri.tsx
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { View, ActivityIndicator, Platform } from 'react-native';
import Svg, {
  Circle,
  Ellipse,
  G,
  Path,
  Polygon,
  Polyline,
  Line,
  Rect,
  Use,
  Symbol,
  Defs,
  LinearGradient,
  RadialGradient,
  Stop,
  ClipPath,
  Pattern,
  Mask,
  SvgProps,
} from 'react-native-svg';
import {
  SvgUriProps,
  ParsedSvg,
  ParsedSvgElement,
  SvgElementAttributes,
  Transform,
  ParsedDef,
  StyleDefinition,
} from '@/types/svg';
import { atob } from 'react-native-quick-base64'

class SvgParseError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SvgParseError';
  }
}

const SVG_COMPONENTS: Record<string, React.ComponentType<any>> = {
  path: Path,
  circle: Circle,
  ellipse: Ellipse,
  g: G,
  polygon: Polygon,
  polyline: Polyline,
  line: Line,
  rect: Rect,
  use: Use,
  symbol: Symbol,
  defs: Defs,
  lineargradient: LinearGradient,
  radialgradient: RadialGradient,
  stop: Stop,
  clippath: ClipPath,
  pattern: Pattern,
  mask: Mask,
};

// Add DOM type definitions
interface DOMElement extends Element {
  tagName: string;
  getAttribute: (name: string) => string | null;
  attributes: NamedNodeMap;
  children: HTMLCollection;
  getElementsByTagName: (tagName: string) => HTMLCollectionOf<Element>;
  textContent: string | null;
  id: string;
}

interface DOMAttribute {
  name: string;
  value: string;
}

interface HTMLCollectionOfDOMElements {
  length: number;
  item: (index: number) => DOMElement | null;
  namedItem: (name: string) => DOMElement | null;
  [index: number]: DOMElement;
}

interface ParsedDocument {
  getElementsByTagName: (tagName: string) => HTMLCollectionOfDOMElements;
}

const AdvancedSvgUri: React.FC<SvgUriProps> = ({
  uri,
  width,
  height,
  fill,
  stroke,
  scale = 1,
  onError,
  onLoad,
  style,
  preserveAspectRatio = 'xMidYMid meet',
  color,
  colorOverrides = {},
  fallbackElement,
}) => {
  const [svgContent, setSvgContent] = useState<ParsedSvg | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  const parseCssText = useCallback((cssText: string): Record<string, any> => {
    const style: Record<string, any> = {};
    const rules = cssText.split(';').filter(Boolean);
    
    rules.forEach(rule => {
      const [property, value] = rule.split(':').map(str => str.trim());
      if (property && value) {
        const camelCaseProperty = property.replace(/-([a-z])/g, g => g[1].toUpperCase());
        style[camelCaseProperty] = value;
      }
    });
    
    return style;
  }, []);

  const parseStylesheet = useCallback((styleText: string): StyleDefinition[] => {
    const rules: StyleDefinition[] = [];
    const ruleRegex = /([^{]+)\{([^}]+)\}/g;
    let match: RegExpExecArray | null;

    while ((match = ruleRegex.exec(styleText)) !== null) {
      const selector = match[1].trim();
      const properties = parseCssText(match[2].trim());
      rules.push({ selector, properties });
    }

    return rules;
  }, [parseCssText]);

  const processStyles = useCallback((
    element: Element,
    styleDefinitions: StyleDefinition[]
  ): Record<string, any> => {
    const styles: Record<string, any> = {};
    
    // Process inline styles
    const inlineStyle = element.getAttribute('style');
    if (inlineStyle) {
      Object.assign(styles, parseCssText(inlineStyle));
    }

    // Process class styles
    const classNames = element.getAttribute('class')?.split(' ') || [];
    classNames.forEach(className => {
      const matchingStyles = styleDefinitions.filter(def => 
        def.selector.includes(`.${className}`)
      );
      matchingStyles.forEach(style => {
        Object.assign(styles, style.properties);
      });
    });

    return styles;
  }, [parseCssText]);

  const parseTransform = useCallback((transform: string): Transform[] => {
    const transforms: Transform[] = [];
    const transformRegex = /(\w+)\(([^)]+)\)/g;
    let match: RegExpExecArray | null;

    while ((match = transformRegex.exec(transform)) !== null) {
      const [, type, valueStr] = match;
      const values = valueStr.split(/[\s,]+/).map(Number);

      switch (type) {
        case 'translate':
          transforms.push({
            translateX: values[0],
            translateY: values[1] || 0
          });
          break;
        case 'scale':
          transforms.push({
            scale: values[0]
          });
          break;
        case 'rotate':
          transforms.push({
            rotate: `${values[0]}deg`
          });
          break;
        case 'skewX':
          transforms.push({
            skewX: `${values[0]}deg`
          });
          break;
        case 'skewY':
          transforms.push({
            skewY: `${values[0]}deg`
          });
          break;
      }
    }

    return transforms;
  }, []);

  const processAttributes = useCallback((
    element: DOMElement,
    styleDefinitions: StyleDefinition[]
  ): SvgElementAttributes => {
    const attributes: SvgElementAttributes = {};
    
    // Process all attributes
    Array.from(element.attributes).forEach((attr: DOMAttribute) => {
      let value: string | number | Transform[] = attr.value;
      
      if (['fill', 'stroke'].includes(attr.name)) {
        value = colorOverrides[attr.value] || attr.value;
      } else if (attr.name === 'transform') {
        value = parseTransform(attr.value);
      } else if (['width', 'height', 'x', 'y', 'cx', 'cy', 'r', 'rx', 'ry'].includes(attr.name)) {
        const num = parseFloat(attr.value);
        if (!isNaN(num)) value = num;
      }
      
      attributes[attr.name] = value;
    });

    // Process styles
    const styles = processStyles(element, styleDefinitions);
    Object.assign(attributes, styles);

    return attributes;
  }, [parseTransform, processStyles, colorOverrides]);

  const parseElement = useCallback((
    element: DOMElement,
    styleDefinitions: StyleDefinition[]
  ): ParsedSvgElement => {
    return {
      type: element.tagName.toLowerCase(),
      attributes: processAttributes(element, styleDefinitions),
      children: Array.from(element.children).map(child => 
        parseElement(child as DOMElement, styleDefinitions)
      )
    };
  }, [processAttributes]);

  const parseSvgContent = useCallback((content: string): ParsedSvg => {
    // Use window.DOMParser for web or a custom implementation for React Native
    const parser = typeof window !== 'undefined' 
      ? new window.DOMParser() 
      : {
          parseFromString: (text: string) => {
            // Custom parser implementation for React Native
            const emptyCollection = {
              length: 0,
              item: (index: number) => null,
              namedItem: (name: string) => null,
              // Add a dummy element to satisfy the index signature
              0: null as unknown as DOMElement,
              // Remove the Symbol.iterator as it's not needed
            } as HTMLCollectionOfDOMElements;

            const doc: ParsedDocument = {
              getElementsByTagName: (tagName: string) => emptyCollection
            };

            return doc;
          }
        };

    const doc = parser.parseFromString(content, 'image/svg+xml');
    const svgElements = doc.getElementsByTagName('svg');
    
    if (svgElements.length === 0) {
      throw new SvgParseError('Invalid SVG content');
    }

    const svgElement = svgElements[0];
    
    // Parse styles from defs
    const styleElements = Array.from(doc.getElementsByTagName('style'));
    const styleDefinitions: StyleDefinition[] = styleElements
      .map(style => parseStylesheet((style as DOMElement).textContent || ''))
      .flat();

    // Parse defs
    const defs: ParsedDef[] = Array.from(svgElement.getElementsByTagName('defs'))
      .map(def => Array.from((def as DOMElement).children)
        .map((child: Element) => ({
          type: (child as DOMElement).tagName.toLowerCase() as ParsedDef['type'],
          id: (child as DOMElement).id,
          content: (child as DOMElement).textContent || '',
          elements: Array.from((child as DOMElement).children).map(el => 
            parseElement(el as DOMElement, styleDefinitions)
          )
        }))
      ).flat();

    return {
      viewBox: svgElement.getAttribute('viewBox') || '',
      width: svgElement.getAttribute('width') || '',
      height: svgElement.getAttribute('height') || '',
      elements: Array.from(svgElement.children)
        .filter(child => (child as DOMElement).tagName.toLowerCase() !== 'defs')
        .map(child => parseElement(child as DOMElement, styleDefinitions)),
      defs
    };
  }, [parseElement, parseStylesheet]);

  const renderElement = useCallback(({ type, attributes, children }: ParsedSvgElement) => {
    const Component = SVG_COMPONENTS[type];

    if (!Component) {
      console.warn(`Unsupported SVG element: ${type}`);
      return null;
    }

    return (
      <Component key={Math.random()} {...attributes}>
        {children?.map(renderElement)}
      </Component>
    );
  }, []);

  // Rest of the component implementation (useEffect, render logic) remains the same
  // but benefits from the improved type safety...

  useEffect(() => {
    const fetchSvg = async () => {
      try {
        setLoading(true);
        
        let response: Response;
        if (uri.startsWith('data:')) {
          const content = atob(uri.split(',')[1]);
          response = new Response(content);
        } else {
          response = await fetch(uri);
        }
        
        if (!response.ok) {
          throw new Error(`Failed to fetch SVG: ${response.statusText}`);
        }

        const svgText = await response.text();
        const parsed = parseSvgContent(svgText);
        setSvgContent(parsed);
        onLoad?.();
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to load SVG');
        setError(error);
        onError?.(error);
        console.error('SVG loading error:', error);
      } finally {
        setLoading(false);
      }
    };

    if (uri) {
      fetchSvg();
    }
  }, [uri, parseSvgContent, onError, onLoad]);

  const dimensions = useMemo(() => {
    if (!svgContent) return { width: 0, height: 0 };
    
    const viewBoxDimensions = svgContent.viewBox.split(' ').map(Number);
    const originalWidth = parseFloat(svgContent.width) || viewBoxDimensions[2] || 0;
    const originalHeight = parseFloat(svgContent.height) || viewBoxDimensions[3] || 0;
    
    let finalWidth = typeof width === 'number' ? width : parseFloat(width || '') || originalWidth;
    let finalHeight = typeof height === 'number' ? height : parseFloat(height || '') || originalHeight;
    
    finalWidth *= scale;
    finalHeight *= scale;
    
    return { width: finalWidth, height: finalHeight };
  }, [svgContent, width, height, scale]);

  if (loading) {
    return (
      <View style={[{ width: dimensions.width, height: dimensions.height, justifyContent: 'center', alignItems: 'center' }, style]}>
        <ActivityIndicator />
      </View>
    );
  }

  if (error || !svgContent) {
    return fallbackElement || (
      <View style={[{ width: dimensions.width, height: dimensions.height }, style]} />
    );
  }

  return (
    <Svg
      width={dimensions.width}
      height={dimensions.height}
      viewBox={svgContent.viewBox}
      preserveAspectRatio={preserveAspectRatio}
      style={style}
    >
      {svgContent.elements.map(renderElement)}
    </Svg>
  );
};

export default AdvancedSvgUri;