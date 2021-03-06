module Neo4j
  module Wrapper
    module Rule


      # Holds all defined rules added by the Neo4j::Rule::ClassMethods#rule method.
      #
      # @see Neo4j::Wrapper::Rule::ClassMethods
      class Rule

        attr_reader :rule_name, :filter, :triggers, :functions

        def initialize(rule_name, props, &block)
          @rule_name = rule_name
          @triggers = props[:triggers]
          @functions = props[:functions]
          @triggers = [@triggers] if @triggers && !@triggers.respond_to?(:each)
          @functions = [@functions] if @functions && !@functions.respond_to?(:each)
          @filter = block
          @bulk_update = bulk_update
        end

        def bulk_update
          return false if @filter
          return true if @functions.nil?
          # only one function allowed for bulk update
          return false if @functions.size != 1
          @functions.first.class.function_name == :size
        end

        def to_s
          "Rule #{rule_name} props=#{props.inspect}"
        end

        def find_function(function_name, function_id)
          function_id = function_id.to_s
          @functions && @functions.find { |f| f.function_id == function_id && f.class.function_name == function_name }
        end

        # Reconstruct the properties given when created this rule
        # Needed when inheriting a rule and we want to duplicate a rule
        def props
          props = {}
          props[:triggers] = @triggers if @triggers
          props[:functions] = @functions if @functions
          props
        end

        def functions_for(property)
          @functions && @functions.find_all { |f| f.calculate?(property) }
        end

        def execute_filter(node)
          if @filter.nil?
            true
          elsif @filter.arity != 1
            node.wrapper.instance_eval(&@filter)
          else
            @filter.call(node)
          end
        end

        def bulk_update?
          @bulk_update
        end

        # ------------------------------------------------------------------------------------------------------------------
        # Class Methods
        # ------------------------------------------------------------------------------------------------------------------

        @rule_nodes = {}

        @lock = Java::java.lang.Object.new

        class << self

          def add(clazz, rule_name, props, &block)
            rule_node = rule_node_for(clazz.to_s)
            rule_node.remove_rule(rule_name) # remove any previously inherited rules
            rule = Rule.new(rule_name, props, &block)
            rule_node.add_rule(rule)
            rule
          end

          def rule_names_for(clazz)
            rule_node = rule_node_for(clazz)
            rule_node.rules.map { |rule| rule.rule_name }
          end

          def rule_node_for(clazz)
            return nil if clazz.nil?
            @lock.synchronized do
              @rule_nodes[clazz.to_s] ||= RuleNode.new(clazz)
            end
          end

          def find_rule_node(node)
            @rule_nodes && @rule_nodes.values.find { |rn| rn.rule_node?(node) }
          end

          def inherit(parent_class, subclass)
            # copy all the rules
            if rule_node = rule_node_for(parent_class)
              rule_node.inherit(subclass)
            end
          end

          def trigger?(node)
            classname = node[:_classname]
            @rule_nodes && classname && rule_node_for(classname) && !rule_node_for(classname).bulk_update?
          end

          def trigger_rules(node, *changes)
            classname = node[:_classname]
            return unless classname # there are no rules if there is not a :_classname property
            rule_node = rule_node_for(classname)
            rule_node.execute_rules(node, *changes)

            # recursively add relationships for all the parent classes with rules that also pass for this node
            recursive(node, rule_node.model_class, *changes)
          end

          def bulk_trigger_rules(classname, class_change, map)
            rule_node = rule_node_for(classname)
            return if rule_node.rules.size > 1 # this optimization is not allowed when using more then one rule
            rule_node.classes_changed(class_change)
            if (clazz = rule_node.model_class.superclass) && clazz.include?(Neo4j::NodeMixin)
              bulk_trigger_rules(clazz.name, class_change, map) if clazz.to_s != "Neo4j::Rails::Model"
            end
          end

          private

          def recursive(node, model_class, *changes)
            if (clazz = model_class.superclass) && clazz.include?(Neo4j::NodeMixin)
              if clazz.to_s != "Neo4j::Rails::Model"
                rule_node = rule_node_for(clazz)
                rule_node && rule_node.execute_rules(node, *changes)
                recursive(node, clazz, *changes)
              end
            end
          end
        end
      end
    end
  end
end