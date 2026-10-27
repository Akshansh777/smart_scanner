
import 'package:flutter/material.dart';

class HomepageContainers extends StatelessWidget {
  final IconData ic;
  final String name;
  final VoidCallback onClick;

  const HomepageContainers({
    super.key,
    required this.ic,
    required this.name,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 190,
          width: 190,
          decoration: BoxDecoration(
            color: const Color.fromARGB(66, 248, 245, 245),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(179, 246, 244, 244),
                spreadRadius: 1,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onClick,
                icon: Icon(ic),
                iconSize: 40,
                color: const Color.fromARGB(255, 3, 132, 238),
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
