
// Qt includes
#include <QApplication>
#include <QTimer>

// CTK includes
#include "ctkCommandLineParser.h"
#include "ctkBBTKShell.h"


//-----------------------------------------------------------------------------
int ctkBBTKShellTest1(int argc, char * argv [] )
{
  QApplication app(argc, argv);
  
  // Command line parser
  ctkCommandLineParser parser;
  parser.addArgument("", "-I", QVariant::Bool);
  parser.addArgument("", "-D", QVariant::String);
  
  bool ok = false;
  QHash<QString, QVariant> parsedArgs = parser.parseArguments(app.arguments(), &ok);
  if (!ok)
    {
    std::cerr << qPrintable(parser.errorString()) << std::endl;
    return EXIT_FAILURE;
    }
    
  bool interactive = parsedArgs["-I"].toBool();
  QString data_directory = parsedArgs["-D"].toString();
  
  // Create an interpreter
  bbtk::Interpreter::Pointer interpreter = bbtk::Interpreter::New();

  // Interpret the file supposed to define a box called 'Processing'
  //I->InterpretFile("bbProcessing.bbs");

  ctkBBTKShell bbtkShell(interpreter);
  bbtkShell.resize(QSize(800, 600));
  bbtkShell.show();
  
  if (!interactive)
    {
    QTimer::singleShot(1000, &app, SLOT(quit()));
    }
  return app.exec();
  
}
