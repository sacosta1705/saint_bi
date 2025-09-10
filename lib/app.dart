import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:saint_bi/core/bloc/auth/auth_bloc.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart';
import 'package:saint_bi/core/bloc/monthly_sales/monthly_sales_bloc.dart';
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/data/sources/local/database_service.dart';
import 'package:saint_bi/core/data/sources/remote/saint_api.dart';
import 'package:saint_bi/core/data/repositories/auth_repository.dart';
import 'package:saint_bi/core/data/repositories/connection_repository.dart';
import 'package:saint_bi/core/data/repositories/summary_repository.dart';
import 'package:saint_bi/core/services/ai_analysis_service.dart';
import 'package:saint_bi/core/services/summary_calculator_service.dart';
import 'package:saint_bi/ui/pages/shared/loading_screen.dart';
import 'package:saint_bi/ui/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SaintApi>(create: (context) => SaintApi()),
        RepositoryProvider<DatabaseService>(
          create: (context) => DatabaseService.instance,
        ),
        RepositoryProvider<ManagementSummaryCalculator>(
          create: (context) => ManagementSummaryCalculator(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) =>
              AuthRepository(saintApiClient: context.read<SaintApi>()),
        ),
        RepositoryProvider<ConnectionRepository>(
          create: (context) =>
              ConnectionRepository(dbService: context.read<DatabaseService>()),
        ),
        RepositoryProvider<SummaryRepository>(
          create: (context) =>
              SummaryRepository(apiClient: context.read<SaintApi>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionBloc>(
            create: (context) => ConnectionBloc(
              connectionRepository: context.read<ConnectionRepository>(),
            )..add(ConnectionsLoaded()),
          ),
          RepositoryProvider<AiAnalysisService>(
            create: (context) => AiAnalysisService(),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              connectionBloc: context.read<ConnectionBloc>(),
            ),
          ),
          BlocProvider<SummaryBloc>(
            create: (context) => SummaryBloc(
              summaryRepository: context.read<SummaryRepository>(),
              authBloc: context.read<AuthBloc>(),
              connectionBloc: context.read<ConnectionBloc>(),
              calculator: context.read<ManagementSummaryCalculator>(),
            ),
          ),
          BlocProvider<MonthlySalesBloc>(
            create: (context) => MonthlySalesBloc(
              summaryRepository: context.read<SummaryRepository>(),
              authBloc: context.read<AuthBloc>(),
              connectionBloc: context.read<ConnectionBloc>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Saint BI',
          theme: AppTheme.lightTheme,
          home: const LoadingScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'), // Inglés (Estados Unidos)
            Locale('es', 'US'), // Español (Estados Unidos)
            Locale('en', 'CA'), // Inglés (Canadá)
            Locale('fr', 'CA'), // Francés (Canadá)
            Locale('es', 'MX'), // Español (México)
            Locale('es', 'GT'), // Español (Guatemala)
            Locale('es', 'BZ'), // Español (Belice)
            Locale('en', 'BZ'), // Inglés (Belice)
            Locale('es', 'SV'), // Español (El Salvador)
            Locale('es', 'HN'), // Español (Honduras)
            Locale('es', 'NI'), // Español (Nicaragua)
            Locale('es', 'CR'), // Español (Costa Rica)
            Locale('es', 'PA'), // Español (Panamá)
            Locale('es', 'CU'), // Español (Cuba)
            Locale('en', 'BS'), // Inglés (Bahamas)
            Locale('en', 'JM'), // Inglés (Jamaica)
            Locale('fr', 'HT'), // Francés (Haití)
            Locale('es', 'DO'), // Español (República Dominicana)
            Locale('es', 'PR'), // Español (Puerto Rico)
            Locale('en', 'TT'), // Inglés (Trinidad y Tobago)
            Locale('nl', 'AW'), // Neerlandés (Aruba)
            Locale('en', 'AG'), // Inglés (Antigua y Barbuda)
            Locale('en', 'BB'), // Inglés (Barbados)
            Locale('en', 'DM'), // Inglés (Dominica)
            Locale('en', 'GD'), // Inglés (Granada)
            Locale('en', 'KN'), // Inglés (San Cristóbal y Nieves)
            Locale('en', 'LC'), // Inglés (Santa Lucía)
            Locale('en', 'VC'), // Inglés (San Vicente y las Granadinas)
            Locale('es', 'CO'), // Español (Colombia)
            Locale('es', 'VE'), // Español (Venezuela)
            Locale('en', 'GY'), // Inglés (Guyana)
            Locale('nl', 'SR'), // Neerlandés (Surinam)
            Locale('fr', 'GF'), // Francés (Guayana Francesa)
            Locale('pt', 'BR'), // Portugués (Brasil)
            Locale('es', 'EC'), // Español (Ecuador)
            Locale('es', 'PE'), // Español (Perú)
            Locale('es', 'BO'), // Español (Bolivia)
            Locale('es', 'PY'), // Español (Paraguay)
            Locale('es', 'CL'), // Español (Chile)
            Locale('es', 'AR'), // Español (Argentina)
            Locale('es', 'UY'), // Español (Uruguay)
          ],
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
