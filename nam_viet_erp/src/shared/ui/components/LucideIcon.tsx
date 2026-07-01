import React from "react";
import * as LucideIcons from "lucide-react";

interface IconProps {
  name?: string;
  size?: number;
  color?: string;
  strokeWidth?: number;
  className?: string;
}

export const LucideIcon: React.FC<IconProps> = ({
  name,
  size = 20,
  color = "currentColor",
  strokeWidth = 1.5,
  className = "",
}) => {
  if (!name) return null;
  const IconComponent = (LucideIcons as any)[name];
  if (!IconComponent) return null;

  return (
    <IconComponent
      size={size}
      color={color}
      strokeWidth={strokeWidth}
      className={className}
    />
  );
};
