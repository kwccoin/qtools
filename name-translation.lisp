#|
This file is a part of Qtools
(c) 2014 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.qtools)

(defvar *translators* ())

(defclass translator ()
  ((name :initarg :name :accessor name)
   (translation :initarg :translation :accessor translation)
   (priority :initarg :priority :accessor priority))
  (:default-initargs
   :name (error "NAME required.")
   :translation (error "TRANSLATION required.")
   :priority 0))

(defun translator (name)
  (let ((translator (find name *translators* :key #'name)))
    (when translator (translation translator))))

(defun (setf translator) (translation name &optional (priority 0))
  (remove-translator name)
  (let ((translator (make-instance 'translator :name name :translation translation :priority priority)))
    (setf *translators* (sort (cons translator *translators*) #'> :key #'priority))))

(defun remove-translator (name)
  (setf *translators* (remove name *translators* :key #'name)))

(defun translate-name (name type &optional (error-p T))
  (or (loop for translator in *translators*
            thereis (funcall translator name type))
      (when error-p
        (error "Don't know how to translate ~a to ~a." name type))))

(defmacro define-translator (name (source type &optional (priority 0)) &body body)
  `(progn (setf (translator ',name ,priority)
                (lambda (,source ,type) ,@body))
          ',name))

(defmacro define-simple-translator ((type name &optional (priority 0)) (source) &body body)
  (let ((target (gensym "TARGET")))
    `(define-translator ,(intern (format NIL "~a-~a" type name)) (,source ,target ,priority)
       (when (eql ,target ',type)
         ,@body))))

(defmacro define-1->1-translator (type match result &key (test '#'string-equal) (priority 0))
  (let ((name (gensym "TYPE")))
    `(define-simple-translator (,type ,(intern (princ-to-string match)) ,priority) (,name)
       (when (funcall ,test ,name ',match)
         ',result))))

(define-1->1-translator cffi "bool" :bool)
(define-1->1-translator cffi "char" :char)
(define-1->1-translator cffi "unsigned char" :uchar)
(define-1->1-translator cffi "short" :short)
(define-1->1-translator cffi "unsigned short" :ushort)
(define-1->1-translator cffi "int" :int)
(define-1->1-translator cffi "unsigned int" :uint)
(define-1->1-translator cffi "long" :long)
(define-1->1-translator cffi "unsigned long" :ulong)
(define-1->1-translator cffi "long long" :llong)
(define-1->1-translator cffi "unsigned long long" :ullong)
(define-1->1-translator cffi "uchar" :uchar)
(define-1->1-translator cffi "ushort" :ushort)
(define-1->1-translator cffi "uint" :uint)
(define-1->1-translator cffi "ulong" :ulong)
(define-1->1-translator cffi "llong" :llong)
(define-1->1-translator cffi "ullong" :ullong)
(define-1->1-translator cffi "float" :float)
(define-1->1-translator cffi "double" :double)
(define-1->1-translator cffi "long double" :long-double)
(define-1->1-translator cffi "const char*" :string)
(define-1->1-translator cffi "const QString&" :string)
(define-1->1-translator cffi :unsigned-char :uchar)
(define-1->1-translator cffi :unsigned-short :ushort)
(define-1->1-translator cffi :unsigned-int :uint)
(define-1->1-translator cffi :unsigned-long :ulong)
(define-1->1-translator cffi :long-long :llong)
(define-1->1-translator cffi :unsigned-long-long :ullong)
(define-simple-translator (cffi cffi-types -10) (type)
  ;; Might already be a valid CFFI type!
  (when (or (listp type) (symbolp type))
    type))

(define-1->1-translator stack-item "pointer" qt::ptr)
(define-1->1-translator stack-item "bool" qt::bool)
(define-1->1-translator stack-item "char" qt::char)
(define-1->1-translator stack-item "uchar" qt::uchar)
(define-1->1-translator stack-item "unsigned-char" qt::uchar)
(define-1->1-translator stack-item "short" qt::short)
(define-1->1-translator stack-item "ushort" qt::ushort)
(define-1->1-translator stack-item "unsigned-short" qt::ushort)
(define-1->1-translator stack-item "int" qt::int)
(define-1->1-translator stack-item "uint" qt::uint)
(define-1->1-translator stack-item "unsigned-int" qt::uint)
(define-1->1-translator stack-item "long" qt::long)
(define-1->1-translator stack-item "ulong" qt::ulong)
(define-1->1-translator stack-item "unsigned-long" qt::ulong)
(define-1->1-translator stack-item "float" qt::float)
(define-1->1-translator stack-item "double" qt::double)
(define-simple-translator (stack-item enum -5) (type)
  (when (search "::" (string type))
    'qt::enum))
(define-simple-translator (stack-item stack-item -10) (type)
  (let ((type (typecase type
                (integer type)
                (string (qt::find-qtype type))
                (symbol (qt::find-qtype (string type))))))
    (when type
      (qt::qtype-stack-item-slot type))))

(defun substring-type-p (test type)
  (search (string type) test))

(define-1->1-translator type "bool" boolean)
(define-1->1-translator type "char" (signed-byte 8))
(define-1->1-translator type "unsigned char" (unsigned-byte 8))
(define-1->1-translator type "short" (signed-byte 16))
(define-1->1-translator type "unsigned short" (unsigned-byte 16))
(define-1->1-translator type "int" (signed-byte 32))
(define-1->1-translator type "unsigned int" (unsigned-byte 32))
(define-1->1-translator type "long" (signed-byte 64))
(define-1->1-translator type "unsigned long" (unsigned-byte 64))
(define-1->1-translator type "long long" (signed-byte 64))
(define-1->1-translator type "unsigned long long" (unsigned-byte 64))
(define-1->1-translator type "float" single-float)
(define-1->1-translator type "double" double-float)
(define-1->1-translator type "QString" string :test #'substring-type-p)
(define-1->1-translator type "QObject" qobject :test #'substring-type-p)
(define-1->1-translator type "QWidget" qobject :test #'substring-type-p)
(define-simple-translator (type type -10) (type)
  (when (or (listp type) (symbolp type))
    type))

(define-1->1-translator class "bool" T)
(define-1->1-translator class "char" integer)
(define-1->1-translator class "unsigned char" integer)
(define-1->1-translator class "short" integer)
(define-1->1-translator class "unsigned short" integer)
(define-1->1-translator class "int" integer)
(define-1->1-translator class "unsigned int" integer)
(define-1->1-translator class "long" integer)
(define-1->1-translator class "unsigned long" integer)
(define-1->1-translator class "long long" integer)
(define-1->1-translator class "unsigned long long" integer)
(define-1->1-translator class "float" float)
(define-1->1-translator class "double" float)
(define-1->1-translator class "QString" string :test #'substring-type-p)
(define-1->1-translator class "QObject" qobject :test #'substring-type-p)
(define-1->1-translator class "QWidget" qobject :test #'substring-type-p)
(define-simple-translator (class class -10) (type)
  (when (find-class type NIL)
    type))

(define-1->1-translator qtype boolean "bool" :test #'subtypep)
(define-1->1-translator qtype (signed-byte 8) "char" :test #'subtypep)
(define-1->1-translator qtype (unsigned-byte 8) "unsigned char" :test #'subtypep)
(define-1->1-translator qtype (signed-byte 16) "short" :test #'subtypep)
(define-1->1-translator qtype (unsigned-byte 16) "unsigned short" :test #'subtypep)
(define-1->1-translator qtype (signed-byte 32) "int" :test #'subtypep)
(define-1->1-translator qtype (unsigned-byte 32) "unsigned int" :test #'subtypep)
(define-1->1-translator qtype (signed-byte 64) "long" :test #'subtypep)
(define-1->1-translator qtype (unsigned-byte 64) "unsigned long" :test #'subtypep)
(define-1->1-translator qtype (signed-byte 64) "long long" :test #'subtypep)
(define-1->1-translator qtype (unsigned-byte 64) "unsigned long long" :test #'subtypep)
(define-1->1-translator qtype fixnum "long" :test #'subtypep)
(define-1->1-translator qtype single-float "float" :test #'subtypep)
(define-1->1-translator qtype double-float "double" :test #'subtypep)
(define-1->1-translator qtype string "const QString&" :test #'subtypep)
(define-1->1-translator qtype qobject "const QObject&" :test #'subtypep)
(define-simple-translator (qtype qtype -10) (type)
  (when (qt::find-qtype type)
    type))

(define-simple-translator (qclass qclass) (name)
  (typecase name
    (string name)
    (symbol (find-qt-class-name name))))

(defun to-method-name (thing)
  (etypecase thing
    (string thing)
    (symbol (capitalize-on #\- thing NIL))))

(defun qt-type-of (object)
  (qt-type-for (type-of object)))

(defun qt-type-for (cl-type)
  (translate-name cl-type 'qtype NIL))

(defun to-type-name (thing)
  (etypecase thing
    (string thing)
    (symbol (or (qt-type-for thing)
                (string-downcase thing)))))

(defun cl-type-for (qt-type)
  (translate-name qt-type 'type NIL))

(defun eqt-type-of (object)
  (or (qt-type-of object)
      (error "No known C++ type for objects of type ~s." (type-of object))))

(defun ecl-type-for (qt-type)
  (or (cl-type-for qt-type)
      (error "No known CL type for type ~s." qt-type)))

(defun %determined-type-method-name-arg (stream arg a b)
  (declare (ignore a b))
  (write-string (if (listp arg)
                    (to-type-name (second arg))
                    (eqt-type-of arg))
                stream))

(defun determined-type-method-name (function args)
  (format NIL "~a(~{~/qtools::%determined-type-method-name-arg/~^, ~})"
          (to-method-name function) args))

(defun %specified-type-method-name-arg (stream arg a b)
  (declare (ignore a b))
  (write-string (to-type-name arg) stream))

(defun specified-type-method-name (function args)
  (format NIL "~a(~{~/qtools::%specified-type-method-name-arg/~^, ~})"
          (to-method-name function) args))
