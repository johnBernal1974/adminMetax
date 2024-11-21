import 'package:flutter/material.dart';

class TravelHistoryFilters extends StatefulWidget {
  final void Function(DateTimeRange?) onFilterChange; // Solo rango de fechas

  const TravelHistoryFilters({Key? key, required this.onFilterChange}) : super(key: key);

  @override
  TravelHistoryFiltersState createState() => TravelHistoryFiltersState();
}

class TravelHistoryFiltersState extends State<TravelHistoryFilters> {
  DateTimeRange? selectedDateRange; // Solo se maneja el rango de fechas

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Selector de rango de fechas
          ElevatedButton(
            onPressed: () async {
              final DateTimeRange? range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020), // Rango mínimo
                lastDate: DateTime.now(),  // Rango máximo
              );
              if (range != null) {
                setState(() {
                  selectedDateRange = range;
                  widget.onFilterChange(selectedDateRange); // Notifica el cambio
                });
              }
            },
            child: Text(
              selectedDateRange == null
                  ? 'Seleccionar rango'
                  : '${selectedDateRange!.start.toString().substring(0, 10)} - ${selectedDateRange!.end.toString().substring(0, 10)}',
            ),
          ),
        ],
      ),
    );
  }
}
