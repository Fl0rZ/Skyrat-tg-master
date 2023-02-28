/// A template used to make composite datatypes for circuits.
/// Used so that we don't have to generate every single possible combination of types
/datum/circuit_composite_template
	/// The datatype this composite template is of.
	var/datatype
	/// The path to the composite type
	var/composite_datatype_path
	/// The amount of composite datatypes needed to generate a datatype from this template
	var/expected_types = 1

	/// Types to generate during initialization
	var/list/types_to_generate = list()

	var/list/datum/circuit_datatype/composite_instance/generated_types = list()

/**
 * Generates a name for the datatype using the unique list of composite datatypes.
 * This should always generate a constant value for the input given as it is used as
 * the unique identifier
 **/
/datum/circuit_composite_template/proc/generate_name(list/composite_datatypes)
	SHOULD_BE_PURE(TRUE)
	return "[datatype]<[composite_datatypes.Join(", ")]>"

/**
 * Generates a composite type using this template. Not recommended to use directly, use a define instead.
 *
 * Arguments:
 * * composite_datatypes - The list of composite datatypes to use to generate this type.
 **/
/datum/circuit_composite_template/proc/generate_composite_type(list/composite_datatypes)
	var/new_datatype = generate_name(composite_datatypes)

	if(!GLOB.circuit_datatypes)
		types_to_generate += list(composite_datatypes)
		return new_datatype

	if(expected_types != length(composite_datatypes))
		CRASH("Invalid amount of composite datatypes passed to [type]. Expected [expected_types], got [length(composite_datatypes)] arguments.")

	if(GLOB.circuit_datatypes[new_datatype])
		return new_datatype
	var/is_extensive = FALSE
	for(var/datatype_to_check in composite_datatypes)
		if(!GLOB.circuit_datatypes[datatype_to_check])
			CRASH("Attempted to form an invalid composite datatype using datatypes that don't exist! (got [datatype_to_check], expected a valid datatype)")
		if(GLOB.circuit_datatypes[datatype_to_check].is_extensive)
			is_extensive = TRUE
	var/datum/circuit_datatype/composite_instance/generated_type = new composite_datatype_path(new_datatype, datatype, composite_datatypes)
	if(!generated_type.is_extensive)
		generated_type.is_extensive = is_extensive
	GLOB.circuit_datatypes[new_datatype] = generated_type
	generated_types[new_datatype] = generated_type
	return new_datatype

/**
 * Used to generate composite types from anything that was generated
 * before global variables were all initialized.
 * Used for when composite datatypes are used in globally defined lists, before GLOB.circuit_datatypes is available.
 **/
/datum/circuit_composite_template/proc/Initialize()
	if(types_to_generate)
		for(var/list/data as anything in types_to_generate)
			generate_composite_type(data)

/// A composite instance generated by a template
/datum/circuit_datatype/composite_instance
	datatype_flags = DATATYPE_FLAG_COMPOSITE
	abstract = TRUE

	/// The base datatype, used for comparisons
	var/base_datatype

	/// The composite datatypes that make this datatype up
	var/list/composite_datatypes

	/// A list composed of the composite datatypes sent to the UI.
	var/list/composite_datatypes_style

/datum/circuit_datatype/composite_instance/New(datatype, base_datatype, list/composite_datatypes)
	. = ..()
	if(!datatype || !composite_datatypes)
		return

	src.datatype = datatype
	src.base_datatype = base_datatype
	src.composite_datatypes = composite_datatypes
	abstract = FALSE

	composite_datatypes_style += list()
	for(var/datatype_to_check in composite_datatypes)
		composite_datatypes_style += GLOB.circuit_datatypes[datatype_to_check].color

/datum/circuit_datatype/composite_instance/can_receive_from_datatype(datatype_to_check)
	. = ..()
	if(.)
		return

	var/datum/circuit_datatype/composite_instance/datatype_handler = SSwiremod_composite.get_composite_type(base_datatype, datatype_to_check)
	if(!datatype_handler || length(datatype_handler.composite_datatypes) != length(composite_datatypes))
		return FALSE

	for(var/index in 1 to length(composite_datatypes))
		if(!GLOB.circuit_datatypes[composite_datatypes[index]].can_receive_from_datatype(datatype_handler.composite_datatypes[index]))
			return FALSE
	return TRUE

/datum/circuit_datatype/composite_instance/datatype_ui_data(datum/port/port)
	var/list/ui_data = list()

	ui_data["composite_types"] = composite_datatypes_style
	return ui_data

/datum/circuit_datatype/composite_instance/get_datatypes()
	return composite_datatypes

/datum/circuit_datatype/composite_instance/get_datatype(index)
	if(index > length(composite_datatypes) || index < 0)
		return
	return composite_datatypes[index]