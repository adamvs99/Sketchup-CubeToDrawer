#
#  sketchup.rb
#  Feaux  for unit testing
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

module AdamExtensions
    module Geom
        class Point3d
      def initialize(x_or_col, y_or_nil = nil, z_or_nil = nil)
        case x_or_col
        when Geom::Point3d
          @data = x_or_col.data.dup
        when Array
          raise ArgumentError, "Array must have 3 elements" unless x_or_col.size == 3
          @data = x_or_col.map { |n| Float(n) }
        when Numeric
          raise ArgumentError, "y and z must be provided" if y_or_nil.nil? || z_or_nil.nil?
          @data = [Float(x_or_col), Float(y_or_nil), Float(z_or_nil)]
        else
          raise TypeError, "Unsupported initializer for Point3d: #{x_or_col.class}"
        end
      end

      def data
        @data
      end

      def x; @data[0]; end
      def y; @data[1]; end
      def z; @data[2]; end

      def x=(new_x); @data[0] = Float(new_x); end
      def y=(new_y); @data[1] = Float(new_y); end
      def z=(new_z); @data[2] = Float(new_z); end

      def ==(other)
        other.is_a?(Geom::Point3d) &&
          @data[0] == other.x &&
          @data[1] == other.y &&
          @data[2] == other.z
      end

      def eql?(other)
        self == other
      end

      def hash
        @data.hash
      end

      # Optional helpers for tests
      def to_a
        @data.dup
      end

      def to_s
        "(#{x}, #{y}, #{z})"
      end
    end # class Point3d
  end # module Geom
end #module AdamExtensions
